#!/usr/bin/env node
/**
 * Read-only tenant migration audit.
 *
 * Required environment:
 *   APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1
 *   APPWRITE_PROJECT_ID=essais
 *   APPWRITE_API_KEY=<server-side key with tablesdb.read>
 * Optional:
 *   APPWRITE_DATABASE_ID=6531ad112080ae3b14a7
 *   LEGACY_COMPANY_ID=essais
 *
 * This script never writes to Appwrite. It reports row counts and tenant
 * ownership coverage without printing business data or payload contents.
 */

const endpoint = (process.env.APPWRITE_ENDPOINT || 'https://fra.cloud.appwrite.io/v1').replace(/\/$/, '');
const projectId = process.env.APPWRITE_PROJECT_ID;
const apiKey = process.env.APPWRITE_API_KEY;
const databaseId = process.env.APPWRITE_DATABASE_ID || '6531ad112080ae3b14a7';
const legacyCompanyId = process.env.LEGACY_COMPANY_ID || 'essais';

if (!projectId || !apiKey) {
  console.error('Missing APPWRITE_PROJECT_ID or APPWRITE_API_KEY.');
  process.exit(1);
}

const tenantTables = [
  ['chauffeur', 'driver'],
  ['vehicle', 'vehicle'],
  ['etat', 'vehicle_state'],
  ['doc_vehic', 'vehicle_document'],
  ['reparation', 'repair'],
  ['activity', 'activity'],
  ['chauf_disponibilite', 'driver_availability'],
  ['doc_chauffeur', 'driver_document'],
  ['prestataire', 'provider'],
  ['entreprise', 'company_profile'],
  ['planning', 'planning'],
  ['backup', 'backup'],
  ['options', 'inventory_option'],
  ['categories', 'inventory_category'],
  ['partsbrands', 'inventory_brand'],
  ['parts', 'part'],
  ['storage', 'stock'],
  ['fichereception', 'reception'],
  ['clients', 'client'],
  ['fournisseurs', 'supplier'],
  ['access_teams', 'access_team'],
  ['access_users', 'user_access'],
];

const globalTables = ['genre_vehicule', 'marque'];
const systemTables = ['users', 'trialdate', 'admin_keys', 'limits', 'companies', 'company_memberships'];

async function request(path) {
  const response = await fetch(endpoint + path, {
    headers: {
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(body.message || `Appwrite request failed: ${response.status}`);
  }
  return body;
}

async function listRows(tableId, offset) {
  const params = new URLSearchParams();
  params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
  params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
  return request(`/tablesdb/${databaseId}/tables/${encodeURIComponent(tableId)}/rows?${params}`);
}

async function auditTable(tableId, category) {
  let offset = 0;
  let totalRows = 0;
  let missingCompanyId = 0;
  let matchingLegacyCompany = 0;
  const otherCompanyIds = new Map();
  let rowsWithRowPermissions = 0;
  let rowsWithoutRowPermissions = 0;

  while (true) {
    const page = await listRows(tableId, offset);
    const rows = page.rows || [];
    for (const row of rows) {
      totalRows++;
      const companyId = row.data?.companyId;
      if (typeof companyId !== 'string' || companyId.trim() === '') {
        missingCompanyId++;
      } else if (companyId === legacyCompanyId) {
        matchingLegacyCompany++;
      } else {
        otherCompanyIds.set(companyId, (otherCompanyIds.get(companyId) || 0) + 1);
      }
      if (Array.isArray(row.$permissions) && row.$permissions.length > 0) {
        rowsWithRowPermissions++;
      } else {
        rowsWithoutRowPermissions++;
      }
    }
    if (rows.length < 100) break;
    offset += rows.length;
  }

  return {
    tableId,
    category,
    totalRows,
    missingCompanyId,
    matchingLegacyCompany,
    otherCompanyIds: Object.fromEntries(otherCompanyIds),
    rowsWithRowPermissions,
    rowsWithoutRowPermissions,
  };
}

try {
  const results = [];
  for (const [tableId, category] of tenantTables) {
    results.push(await auditTable(tableId, category));
  }
  console.log(JSON.stringify({
    mode: 'read-only',
    projectId,
    databaseId,
    legacyCompanyId,
    generatedAt: new Date().toISOString(),
    classification: { globalTables, systemTables },
    results,
    totals: results.reduce((sum, item) => ({
      tables: sum.tables + 1,
      rows: sum.rows + item.totalRows,
      missingCompanyId: sum.missingCompanyId + item.missingCompanyId,
      rowsWithoutRowPermissions: sum.rowsWithoutRowPermissions + item.rowsWithoutRowPermissions,
    }), { tables: 0, rows: 0, missingCompanyId: 0, rowsWithoutRowPermissions: 0 }),
  }, null, 2));
} catch (error) {
  console.error(error.message || error);
  process.exit(1);
}
