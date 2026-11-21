import { AsyncLocalStorage } from 'node:async_hooks';
import { createHash, createHmac, randomUUID } from 'node:crypto';

const requestContext = new AsyncLocalStorage();
const DATABASE_ID = '6531ad112080ae3b14a7';
const MEMBERSHIPS = 'company_memberships';
const COMPANIES = 'companies';
const ENTITLEMENTS = 'company_entitlements';
const COMPANY_PROFILE = 'entreprise';
const QUOTA_RESOURCES = {
  vehicle: {
    tableId: '6531ad22153b2a49ca2c',
    maxColumn: 'maxVehicles',
    usedColumn: 'vehiclesUsed',
    label: 'véhicules',
  },
  driver: {
    tableId: '6537d87b492c80f255e8',
    maxColumn: 'maxDrivers',
    usedColumn: 'driversUsed',
    label: 'chauffeurs',
  },
};
const QUOTA_RESOURCE_TABLE_IDS = new Set(
  Object.values(QUOTA_RESOURCES).map(resource => resource.tableId),
);

// Single source of truth for business tables isolated by companyId.
const TENANT_TABLE_IDS = [
  '6537d87b492c80f255e8', // chauffeur
  '6531ad22153b2a49ca2c', // vehicle
  'marque', 'etat', 'doc_vehic', 'reparation', 'activity',
  'chauf_disponibilite', 'doc_chauffeur', 'prestataire', 'entreprise',
  'planning', 'backup', 'options', 'categories', 'partsbrands',
  'parts', 'storage', 'fichereception', 'clients',
  'access_teams', 'access_users', 'fournisseurs',
];

const endpoint = (process.env.APPWRITE_FUNCTION_API_ENDPOINT || 'https://fra.cloud.appwrite.io/v1').replace(/\/$/, '');
const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;

function json(res, status, body) {
  return res.json(body, status);
}

function queryPath(tableId, queries, offset) {
  const params = new URLSearchParams();
  for (const query of queries) {
    params.append('queries[]', JSON.stringify(query));
  }
  params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
  params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
  return `/tablesdb/${DATABASE_ID}/tables/${tableId}/rows?${params.toString()}`;
}

async function appwrite(path, { method = 'GET', body, jwt } = {}) {
  const headers = { 'X-Appwrite-Project': projectId };
  if (jwt) headers['X-Appwrite-JWT'] = jwt;
  else {
    const executionKey = requestContext.getStore()?.apiKey;
    if (!executionKey) throw new Error('Appwrite function execution key is unavailable.');
    headers['X-Appwrite-Key'] = executionKey;
  }
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  const response = await fetch(`${endpoint}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const failure = new Error(payload.message || `Appwrite request failed (${response.status})`);
    failure.status = response.status;
    throw failure;
  }
  return payload;
}

async function authenticate(req) {
  const jwt = req.headers['x-appwrite-user-jwt'];
  if (!jwt) {
    const failure = new Error('Authentication required.');
    failure.status = 401;
    throw failure;
  }
  const account = await appwrite('/account', { jwt });
  return { userId: account.$id };
}

// TablesDB returns column values at the row root; normalize for legacy service code.
function normalizeRow(row) {
  if (!row || row.data) return row;
  const data = Object.fromEntries(
    Object.entries(row).filter(([key]) => !key.startsWith('$') && key !== 'data')
  );
  return { ...row, data };
}

async function listRows(tableId, query) {
  const rows = [];
  let offset = 0;
  while (true) {
    const result = await appwrite(queryPath(tableId, [query], offset));
    const page = result.rows || [];
    rows.push(...page.map(normalizeRow));
    if (page.length < 100) break;
    offset += page.length;
  }
  return rows;
}

async function listAllRows(tableId) {
  const rows = [];
  let offset = 0;
  while (true) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const result = await appwrite(`/tablesdb/${DATABASE_ID}/tables/${tableId}/rows?${params.toString()}`);
    const page = result.rows || [];
    rows.push(...page.map(normalizeRow));
    if (page.length < 100) break;
    offset += page.length;
  }
  return rows;
}

function isPlatformSuperAdmin(userId) {
  const allowed = String(process.env.PLATFORM_SUPER_ADMIN_IDS || '')
    .split(',').map(value => value.trim()).filter(Boolean);
  return allowed.includes(userId);
}

function requirePlatformSuperAdmin(userId) {
  if (!isPlatformSuperAdmin(userId)) {
    const failure = new Error('Platform super-administrator access required.');
    failure.status = 403;
    throw failure;
  }
}

async function getEntitlement(companyId) {
  try {
    const row = await appwrite(`/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${encodeURIComponent(companyId)}`);
    return normalizeRow(row)?.data || {};
  } catch (failure) {
    if (failure.status === 404) return null;
    throw failure;
  }
}

function isEntitlementActive(entitlement, now = Date.now()) {
  if (!entitlement || typeof entitlement !== 'object') return false;
  const startsAt = Date.parse(entitlement.startsAt || '');
  const expiresAt = Date.parse(entitlement.expiresAt || '');
  return Number.isFinite(startsAt) &&
    Number.isFinite(expiresAt) &&
    startsAt <= now &&
    expiresAt > now;
}

async function getCompany(companyId) {
  try {
    return normalizeRow(await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`));
  } catch (failure) {
    if (failure.status === 404) return null;
    throw failure;
  }
}

async function activeMembership(userId, companyId) {
  const rows = await listRows(MEMBERSHIPS, {
    method: 'equal', attribute: 'userId', values: [userId],
  });
  return rows.find(row =>
    row.data?.companyId === companyId && row.data?.status === 'active'
  ) || null;
}

async function requireCompanyAdmin(userId, companyId) {
  const membership = await activeMembership(userId, companyId);
  let platformExploration = false;
  if (isPlatformSuperAdmin(userId)) {
    const prefs = await readUserPrefs(userId);
    platformExploration =
      prefs.parcotoPlatformExploration?.companyId === companyId;
  }
  if (!platformExploration &&
      (!membership || !['owner', 'admin'].includes(membership.data.role))) {
    const failure = new Error('You are not authorized to administer this company.');
    failure.status = 403;
    throw failure;
  }
  const company = await getCompany(companyId);
  if (!company || company.data?.status !== 'active') {
    const failure = new Error('Company is unavailable.');
    failure.status = 404;
    throw failure;
  }
  // Platform administrators may inspect/manage a tenant during exploration.
  // Tenant administrators must have a valid, currently active entitlement.
  if (!platformExploration) {
    const entitlement = await getEntitlement(companyId);
    if (!isEntitlementActive(entitlement)) {
      const failure = new Error('The company license is missing, not yet active, or expired.');
      failure.status = 403;
      throw failure;
    }
  }
  return membership;
}

async function createRow(tableId, rowId, data, permissions = [], transactionId) {
  return appwrite(`/tablesdb/${DATABASE_ID}/tables/${tableId}/rows`, {
    method: 'POST',
    body: {
      rowId,
      data,
      permissions,
      ...(transactionId ? { transactionId } : {}),
    },
  });
}

function tenantRowPermissions(teamId) {
  return [
    `read("team:${teamId}")`,
    `update("team:${teamId}/admin")`,
    `update("team:${teamId}/manager")`,
    `delete("team:${teamId}/admin")`,
  ];
}

async function requireQuotaWriterContext(
  userId,
  companyId,
  { allowExpiredLicense = false, allowManager = true } = {},
) {
  const membership = await activeMembership(userId, companyId);
  let platformExploration = false;
  if (isPlatformSuperAdmin(userId)) {
    const prefs = await readUserPrefs(userId);
    platformExploration =
      prefs.parcotoPlatformExploration?.companyId === companyId;
  }

  const allowedRoles = allowManager
    ? ['owner', 'admin', 'manager']
    : ['owner', 'admin'];
  if (!platformExploration &&
      (!membership || !allowedRoles.includes(membership.data.role))) {
    throw Object.assign(
      new Error('You are not authorized to create or delete resources for this company.'),
      { status: 403 },
    );
  }

  const company = await getCompany(companyId);
  if (!company || company.data?.status !== 'active') {
    throw Object.assign(new Error('Company is unavailable.'), { status: 404 });
  }

  const entitlement = await getEntitlement(companyId);
  // Historical tenants without an explicit entitlement keep their existing
  // unmetered behavior. Once a company has an entitlement row, its license
  // dates and quotas are enforced consistently.
  if (entitlement && !allowExpiredLicense && !isEntitlementActive(entitlement)) {
    throw Object.assign(
      new Error('The company license is not yet active or has expired.'),
      { status: 403 },
    );
  }

  const teamId = String(company.data?.teamId || '').trim();
  if (!teamId) {
    throw Object.assign(
      new Error('The company team is not provisioned.'),
      { status: 409 },
    );
  }

  return { company, entitlement, teamId, membership, platformExploration };
}

async function createQuotaTransaction() {
  return appwrite('/tablesdb/transactions', {
    method: 'POST',
    body: { ttl: 60 },
  });
}

async function finishQuotaTransaction(transactionId, commit) {
  return appwrite(`/tablesdb/transactions/${encodeURIComponent(transactionId)}`, {
    method: 'PATCH',
    body: commit ? { commit: true } : { rollback: true },
  });
}

async function readQuotaResourceRow(resource, rowId) {
  try {
    return normalizeRow(await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${resource.tableId}/rows/${encodeURIComponent(rowId)}`,
    ));
  } catch (failure) {
    if (failure.status === 404) return null;
    throw failure;
  }
}

function quotaExceededFailure(label, used, maximum) {
  return Object.assign(
    new Error(`Le quota autorisé de ${label} est atteint (${used}/${maximum}).`),
    { status: 409, code: 'quota_exceeded' },
  );
}

async function createQuotaResource(userId, input) {
  const resourceKey = String(input.resource || '');
  const resource = QUOTA_RESOURCES[resourceKey];
  const companyId = String(input.companyId || '').trim();
  const rowId = String(input.rowId || '').trim();
  const inputData = input.data && typeof input.data === 'object' && !Array.isArray(input.data)
    ? input.data
    : null;

  if (!resource || !companyId || !rowId || rowId.length > 36 || !inputData) {
    throw Object.assign(
      new Error('A valid resource, companyId, rowId and data object are required.'),
      { status: 400 },
    );
  }

  const { entitlement, teamId } =
    await requireQuotaWriterContext(userId, companyId);
  const maximum = entitlement
    ? Number(entitlement[resource.maxColumn])
    : null;
  const used = entitlement
    ? Number(entitlement[resource.usedColumn] ?? 0)
    : null;
  if (entitlement &&
      (!Number.isSafeInteger(maximum) || maximum < 0 ||
       !Number.isSafeInteger(used) || used < 0)) {
    throw Object.assign(
      new Error(`The ${resourceKey} quota counters are not configured correctly.`),
      { status: 503 },
    );
  }

  // Make queued/offline retries idempotent. A row already committed for this
  // tenant must not consume a second licensed slot.
  const existing = await readQuotaResourceRow(resource, rowId);
  if (existing) {
    if (existing.data?.companyId !== companyId) {
      throw Object.assign(new Error('Resource ID is already used by another company.'), { status: 403 });
    }
    return { created: false, alreadyExists: true, rowId, resource: resourceKey };
  }

  // Legacy tenant without an entitlement row: preserve its former behavior,
  // but still enforce tenant ownership and server-controlled row ACLs.
  if (!entitlement) {
    await createRow(
      resource.tableId,
      rowId,
      { ...inputData, companyId },
      tenantRowPermissions(teamId),
    );
    return {
      created: true,
      alreadyExists: false,
      unmeteredLegacyTenant: true,
      rowId,
      resource: resourceKey,
    };
  }

  if (used >= maximum) {
    throw quotaExceededFailure(resource.label, used, maximum);
  }

  const transaction = await createQuotaTransaction();
  const transactionId = transaction.$id;
  if (!transactionId) {
    throw Object.assign(new Error('Could not start a quota transaction.'), { status: 503 });
  }

  try {
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${encodeURIComponent(companyId)}/${resource.usedColumn}/increment`,
      {
        method: 'PATCH',
        body: {
          value: 1,
          // Appwrite validates the resulting value atomically, so the
          // final permitted create can bring usage exactly up to the quota.
          max: maximum,
          transactionId,
        },
      },
    );

    const data = { ...inputData, companyId };
    delete data.$id;
    delete data.$createdAt;
    delete data.$updatedAt;
    await createRow(
      resource.tableId,
      rowId,
      data,
      tenantRowPermissions(teamId),
      transactionId,
    );
    await finishQuotaTransaction(transactionId, true);
    return { created: true, alreadyExists: false, rowId, resource: resourceKey };
  } catch (failure) {
    try {
      await finishQuotaTransaction(transactionId, false);
    } catch (rollbackFailure) {
      log(`Quota transaction rollback failed for ${resourceKey} ${rowId}: ${rollbackFailure.message}`);
    }

    if ([400, 409].includes(failure.status)) {
      const latest = await getEntitlement(companyId);
      const currentUsed = Number(latest?.[resource.usedColumn] ?? 0);
      if (Number.isSafeInteger(currentUsed) && currentUsed >= maximum) {
        throw quotaExceededFailure(resource.label, currentUsed, maximum);
      }
    }
    throw failure;
  }
}

async function deleteQuotaResource(userId, input) {
  const resourceKey = String(input.resource || '');
  const resource = QUOTA_RESOURCES[resourceKey];
  const companyId = String(input.companyId || '').trim();
  const rowId = String(input.rowId || '').trim();
  if (!resource || !companyId || !/^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/.test(rowId)) {
    throw Object.assign(
      new Error('A valid resource, companyId and Appwrite rowId are required.'),
      { status: 400 },
    );
  }

  const { entitlement } = await requireQuotaWriterContext(
    userId,
    companyId,
    { allowExpiredLicense: true, allowManager: false },
  );
  const existing = await readQuotaResourceRow(resource, rowId);
  if (!existing) return { deleted: false, rowId, resource: resourceKey };
  if (existing.data?.companyId !== companyId) {
    throw Object.assign(new Error('Resource does not belong to the active company.'), { status: 404 });
  }

  // Legacy tenant without entitlement: preserve deletion behavior without
  // touching a usage counter that has never been initialized.
  if (!entitlement) {
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${resource.tableId}/rows/${encodeURIComponent(rowId)}`,
      { method: 'DELETE' },
    );
    return {
      deleted: true,
      unmeteredLegacyTenant: true,
      rowId,
      resource: resourceKey,
    };
  }

  const used = Number(entitlement[resource.usedColumn] ?? 0);
  if (!Number.isSafeInteger(used) || used < 1) {
    throw Object.assign(
      new Error(`The ${resourceKey} usage counter is inconsistent. Reconcile company quotas before deleting this resource.`),
      { status: 409, code: 'quota_counter_mismatch' },
    );
  }

  const transaction = await createQuotaTransaction();
  const transactionId = transaction.$id;
  if (!transactionId) {
    throw Object.assign(new Error('Could not start a quota transaction.'), { status: 503 });
  }

  try {
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${encodeURIComponent(companyId)}/${resource.usedColumn}/decrement`,
      {
        method: 'PATCH',
        body: { value: 1, min: 0, transactionId },
      },
    );
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${resource.tableId}/rows/${encodeURIComponent(rowId)}`,
      { method: 'DELETE', body: { transactionId } },
    );
    await finishQuotaTransaction(transactionId, true);
    return { deleted: true, rowId, resource: resourceKey };
  } catch (failure) {
    try {
      await finishQuotaTransaction(transactionId, false);
    } catch (rollbackFailure) {
      log(`Quota delete rollback failed for ${resourceKey} ${rowId}: ${rollbackFailure.message}`);
    }
    throw failure;
  }
}

async function lockQuotaTableCreatePermissions() {
  const result = [];
  for (const tableId of QUOTA_RESOURCE_TABLE_IDS) {
    const table = await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${encodeURIComponent(tableId)}`,
    );
    const current = table.$permissions || [];
    const next = current.filter(permission => !permission.startsWith('create('));
    const changed = next.length !== current.length || table.rowSecurity !== true;
    if (changed) {
      await appwrite(
        `/tablesdb/${DATABASE_ID}/tables/${encodeURIComponent(tableId)}`,
        { method: 'PUT', body: { permissions: next, rowSecurity: true } },
      );
    }
    result.push({ tableId, removedCreatePermissions: current.length - next.length, changed });
  }
  return result;
}

async function enforceCompanyAccessState(company, entitlement) {
  const teamId = String(company.data?.teamId || '').trim();
  if (!teamId) {
    return { licenseActive: false, aclEnforced: false };
  }
  const licenseActive = company.data?.status === 'active' &&
    isEntitlementActive(entitlement);
  const expectedState = licenseActive ? 'active' : 'inactive';
  if (company.data?.tenantAclLicenseState !== expectedState) {
    await prepareCompanyRows(company.$id, teamId);
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(company.$id)}`,
      {
        method: 'PATCH',
        body: {
          data: {
            tenantAclLicenseState: expectedState,
            tenantAclEnforcedAt: new Date().toISOString(),
          },
        },
      },
    );
  }
  return { licenseActive, aclEnforced: true };
}

async function prepareCompanyRows(companyId, teamId) {
  const company = await getCompany(companyId);
  if (!company) throw Object.assign(new Error('Company not found.'), { status: 404 });
  const entitlement = await getEntitlement(companyId);
  // Missing or malformed entitlements are denied by default. Legacy migration
  // must create a valid entitlement before restoring tenant write access.
  const isActive = company.data?.status === 'active' &&
    isEntitlementActive(entitlement);
  // Global user profiles, system settings and shared reference tables are excluded.
  const tableIds = TENANT_TABLE_IDS;
  const rowPermissions = [
    `read("team:${teamId}")`,
    ...(isActive
      ? [
          `update("team:${teamId}/admin")`,
          `update("team:${teamId}/manager")`,
          `delete("team:${teamId}/admin")`,
        ]
      : []),
  ];
  const result = [];
  let totalUpdated = 0;

  for (const tableId of tableIds) {
    const createPermissions = QUOTA_RESOURCE_TABLE_IDS.has(tableId)
      ? []
      : [
          `create("team:${teamId}/admin")`,
          `create("team:${teamId}/manager")`,
        ];
    const table = await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${encodeURIComponent(tableId)}`
    );
    const columns = table.columns || [];
    if (!columns.some(column => column.key === 'companyId')) {
      throw Object.assign(
        new Error(`Tenant table "${tableId}" is missing the companyId column.`),
        { status: 409 },
      );
    }

    // A tenant table must never inherit broad table-level read/write access.
    // Data access is granted on individual rows to the company's own team.
    // On tenant tables, table-level permissions must never grant read,
    // update or delete access. Those operations are exclusively row-scoped.
    // Keep only team-scoped create grants required by the Flutter client.
    const tablePermissions = new Set(
      (table.$permissions || []).filter(permission =>
        !QUOTA_RESOURCE_TABLE_IDS.has(tableId) &&
        /^create\("team:[^"]+\/(admin|manager)"\)$/.test(permission)
      ),
    );
    let tablePermissionsChanged =
      table.rowSecurity !== true ||
      tablePermissions.size !== (table.$permissions || []).length;
    for (const permission of createPermissions) {
      if (isActive && !tablePermissions.has(permission)) {
        tablePermissions.add(permission);
        tablePermissionsChanged = true;
      } else if (!isActive && tablePermissions.has(permission)) {
        tablePermissions.delete(permission);
        tablePermissionsChanged = true;
      }
    }
    if (tablePermissionsChanged) {
      await appwrite(
        `/tablesdb/${DATABASE_ID}/tables/${encodeURIComponent(tableId)}`,
        {
          method: 'PUT',
          body: { permissions: [...tablePermissions], rowSecurity: true },
        },
      );
    }

    const rows = await listAllRows(tableId);
    const tenantRows = rows.filter(row => row.data?.companyId === companyId);
    let updated = 0;
    const expectedPermissions = [...rowPermissions].sort();
    for (const row of tenantRows) {
      const currentPermissions = [...(row.$permissions || [])].sort();
      if (currentPermissions.length === expectedPermissions.length &&
          currentPermissions.every((permission, index) =>
            permission === expectedPermissions[index]
          )) {
        continue;
      }
      await appwrite(
        `/tablesdb/${DATABASE_ID}/tables/${encodeURIComponent(tableId)}/rows/${encodeURIComponent(row.$id)}`,
        { method: 'PATCH', body: { permissions: rowPermissions } },
      );
      updated++;
    }
    totalUpdated += updated;
    result.push({
      tableId,
      totalRows: rows.length,
      tenantRows: tenantRows.length,
      unassignedRows: rows.filter(row => !row.data?.companyId).length,
      otherCompanyRows: rows.filter(
        row => row.data?.companyId && row.data.companyId !== companyId
      ).length,
      permissionsUpdated: updated,
      createPermissionsAdded: tablePermissionsChanged,
    });
  }

  return {
    companyId,
    teamId,
    totalUpdated,
    permissions: rowPermissions,
    tables: result,
  };
}

function companyEntitlementPermissions(teamId) {
  // Entitlements are billing/security state. Tenant clients may inspect them,
  // but only the trusted server function may mutate or delete them.
  return [`read("team:${teamId}")`];
}

async function ensureCompanyProfile(companyId, companyName, teamId, now, profile = {}) {
  const permissions = [
    `read("team:${teamId}")`,
    `update("team:${teamId}/admin")`,
    `update("team:${teamId}/manager")`,
    `delete("team:${teamId}/admin")`,
  ];
  const existingRows = await listRows(COMPANY_PROFILE, {
    method: 'equal', attribute: 'companyId', values: [companyId],
  });
  if (existingRows.length) {
    const existing = existingRows[0];
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${COMPANY_PROFILE}/rows/${encodeURIComponent(existing.$id)}`,
      { method: 'PATCH', body: { permissions } },
    );
    return { rowId: existing.$id, created: false };
  }

  const rowId = companyId.length <= 36 ? companyId : crypto.randomUUID();
  const name = String(profile.name || companyName).trim().slice(0, 60);
  const address = String(profile.address || '').trim().slice(0, 100);
  const phone = String(profile.phone || '').trim().slice(0, 15);
  const email = String(profile.email || '').trim().slice(0, 254);
  const nif = String(profile.nif || '').trim().slice(0, 30);
  const nis = String(profile.nis || '').trim().slice(0, 30);
  const rc = String(profile.rc || '').trim().slice(0, 30);
  const art = String(profile.art || '').trim().slice(0, 30);
  const description = String(profile.description || '').trim().slice(0, 80);
  const data = {
    nom: name,
    adresse: address,
    telephone: phone,
    ...(email ? { email } : {}),
    nif,
    nis,
    rc,
    art,
    description,
    logo: '',
    filiales: [],
    directions: [],
    departments: [],
    search: [name, address, phone, email, nif, nis, rc, art]
      .filter(Boolean).join(' ').slice(0, 400),
    companyId,
  };
  await createRow(COMPANY_PROFILE, rowId, data, permissions);
  return { rowId, created: true };
}

async function listTeamMemberships(teamId) {
  const memberships = [];
  let offset = 0;
  while (true) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const result = await appwrite(`/teams/${encodeURIComponent(teamId)}/memberships?${params.toString()}`);
    const page = result.memberships || [];
    memberships.push(...page);
    if (page.length < 100) break;
    offset += page.length;
  }
  return memberships;
}

function teamRolesForMembership(role, existingRoles = []) {
  if (existingRoles.includes('owner')) return ['owner', 'admin'];
  if (role === 'owner') return ['owner', 'admin'];
  return [role || 'viewer'];
}

async function syncTeamMembership(teamId, userId, role, name = '') {
  const existing = (await listTeamMemberships(teamId)).find(item => item.userId === userId);
  const roles = teamRolesForMembership(role, existing?.roles || []);
  if (existing) {
    return appwrite(`/teams/${encodeURIComponent(teamId)}/memberships/${encodeURIComponent(existing.$id)}`, {
      method: 'PATCH',
      body: { roles },
    });
  }
  return appwrite(`/teams/${encodeURIComponent(teamId)}/memberships`, {
    method: 'POST',
    body: { userId, roles, name: name || undefined },
  });
}

async function removeTeamMembership(teamId, userId) {
  const existing = (await listTeamMemberships(teamId)).find(item => item.userId === userId);
  if (!existing) return false;
  await appwrite(`/teams/${encodeURIComponent(teamId)}/memberships/${encodeURIComponent(existing.$id)}`, {
    method: 'DELETE',
  });
  return true;
}

async function readUserPrefs(userId) {
  try {
    const result = await appwrite(`/users/${encodeURIComponent(userId)}/prefs`);
    return result && typeof result === 'object' ? result : {};
  } catch (_) {
    return {};
  }
}

async function writeUserPrefs(userId, prefs) {
  return appwrite(`/users/${encodeURIComponent(userId)}/prefs`, {
    method: 'PATCH',
    body: { prefs },
  });
}

// Platform exploration temporarily elevates the Super Admin inside one tenant.
// Restore the exact previous team membership on explicit return and on the next
// platform login, including after an app crash or browser close.
async function restorePlatformExploration(userId) {
  const prefs = await readUserPrefs(userId);
  const state = prefs.parcotoPlatformExploration;
  if (!state || typeof state !== 'object' || !state.teamId) return false;

  const teamId = String(state.teamId);
  const existing = (await listTeamMemberships(teamId))
    .find(item => item.userId === userId);
  if (existing) {
    if (state.existed === true) {
      const roles = Array.isArray(state.previousRoles)
        ? state.previousRoles.filter(role => typeof role === 'string')
        : [];
      if (roles.length) {
        await appwrite(
          `/teams/${encodeURIComponent(teamId)}/memberships/${encodeURIComponent(existing.$id)}`,
          { method: 'PATCH', body: { roles } },
        );
      }
    } else {
      await appwrite(
        `/teams/${encodeURIComponent(teamId)}/memberships/${encodeURIComponent(existing.$id)}`,
        { method: 'DELETE' },
      );
    }
  }

  // Appwrite rejects an empty preferences object. Keep a harmless marker
  // after restoration so the preference payload remains a valid non-empty
  // object and subsequent platform logins do not fail with "Invalid prefs".
  const nextPrefs = { ...prefs };
  nextPrefs.parcotoPlatformExploration = {
    restoredAt: new Date().toISOString(),
  };
  await writeUserPrefs(userId, nextPrefs);
  return true;
}

async function createCompanyTeam(teamId, name) {
  return appwrite('/teams', {
    method: 'POST',
    body: { teamId, name },
  });
}

function slugify(value) {
  return value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 64);
}

const VEHICLE_IMAGE_CATALOG = 'vehicle_image_catalog';
const VEHICLE_IMAGE_BUCKET = 'images';
const CARIMAGES_BASE_URL = 'https://carimagesapi.com';
const VEHICLE_IMAGE_NEGATIVE_TTL_MS = 6 * 60 * 60 * 1000;

function normalizeVehicleImageColor(value) {
  const color = String(value || '').normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '').trim().toLowerCase();
  if (/^(|original|origine|peinture d origine|original paint|default|par defaut)$/.test(color)) {
    return 'original';
  }
  if (/^(noir|black|noire)$/.test(color)) return 'black';
  if (/^(blanc|white|blanche)$/.test(color)) return 'white';
  if (/^(argent|silver|argente|gris clair|gris metallise)$/.test(color)) return 'silver';
  if (/^(gris|grey|gray|anthracite|gris fonce)$/.test(color)) return 'grey';
  if (/^(bleu|blue|bleue)$/.test(color)) return 'blue';
  if (/^(rouge|red)$/.test(color)) return 'red';
  return 'original';
}

function vehicleImageCacheKey(make, model, year, color) {
  const canonical = [
    'vehicle-image-sources-v3',
    make.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim(),
    model.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim(),
    String(year),
    color,
  ].join('|');
  return createHash('sha256').update(canonical).digest('hex');
}

function rfc3986(value) {
  return encodeURIComponent(String(value)).replace(/[!'()*]/g, character =>
    '%' + character.charCodeAt(0).toString(16).toUpperCase()
  );
}

function createCarImagesSignedUrl({ make, model, year, color, apiKey, apiSecret }) {
  const expires = String(Math.floor(Date.now() / 1000) + 60 * 60);
  const params = {
    api_key: apiKey,
    make,
    model,
    year: String(year),
    width: '800',
    format: 'webp',
    view: 'front34',
    type: 'car',
    ...(color !== 'original' ? { color } : {}),
    expires,
  };
  const canonical = Object.keys(params).sort()
    .map(key => `${key}=${rfc3986(params[key])}`)
    .join('&');
  const signature = createHmac('sha256', apiSecret)
    .update(canonical)
    .digest('hex');
  const query = Object.keys({ ...params, sig: signature }).sort()
    .map(key => `${rfc3986(key)}=${rfc3986(key === 'sig' ? signature : params[key])}`)
    .join('&');
  return `${CARIMAGES_BASE_URL}/image?${query}`;
}

async function getVehicleImageCacheRow(rowId) {
  try {
    return normalizeRow(await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${VEHICLE_IMAGE_CATALOG}/rows/${encodeURIComponent(rowId)}`
    ));
  } catch (failure) {
    if (failure.status === 404) return null;
    throw failure;
  }
}

async function saveVehicleImageCacheRow(rowId, data) {
  const existing = await getVehicleImageCacheRow(rowId);
  if (existing) {
    await appwrite(
      `/tablesdb/${DATABASE_ID}/tables/${VEHICLE_IMAGE_CATALOG}/rows/${encodeURIComponent(rowId)}`,
      { method: 'PATCH', body: { data } },
    );
    return getVehicleImageCacheRow(rowId);
  }
  try {
    await createRow(VEHICLE_IMAGE_CATALOG, rowId, data, []);
  } catch (failure) {
    // Concurrent requests can race on the unique cache key. The first row wins.
    if (failure.status !== 409) throw failure;
  }
  return getVehicleImageCacheRow(rowId);
}

async function uploadVehicleImage(fileId, fileName, bytes, mimeType) {
  const form = new FormData();
  form.append('fileId', fileId);
  form.append('file', new Blob([bytes], { type: mimeType }), fileName);
  form.append('permissions[]', 'read("any")');

  const executionKey = requestContext.getStore()?.apiKey;
  if (!executionKey) throw new Error('Appwrite function execution key is unavailable.');
  const response = await fetch(
    `${endpoint}/storage/buckets/${VEHICLE_IMAGE_BUCKET}/files`,
    {
      method: 'POST',
      headers: {
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': executionKey,
      },
      body: form,
    },
  );
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const failure = new Error(payload.message || `Appwrite image upload failed (${response.status})`);
    failure.status = response.status;
    throw failure;
  }
  return payload;
}

async function deleteVehicleImageFile(fileId) {
  if (!fileId) return;
  try {
    await appwrite(
      `/storage/buckets/${VEHICLE_IMAGE_BUCKET}/files/${encodeURIComponent(fileId)}`,
      { method: 'DELETE' },
    );
  } catch (failure) {
    // Cleanup is best-effort: the catalog already points to the newly saved file.
    // A stale orphan is preferable to failing a successful image replacement.
  }
}

async function requireVehicleImageAccess(userId, companyId) {
  if (!companyId) {
    const failure = new Error('companyId is required.');
    failure.status = 400;
    throw failure;
  }
  const membership = await activeMembership(userId, companyId);
  let platformExploration = false;
  if (isPlatformSuperAdmin(userId)) {
    const prefs = await readUserPrefs(userId);
    platformExploration =
      prefs.parcotoPlatformExploration?.companyId === companyId;
  }
  if (!platformExploration && (!membership || membership.data?.status !== 'active')) {
    const failure = new Error('You do not have access to this company.');
    failure.status = 403;
    throw failure;
  }
  const company = await getCompany(companyId);
  if (!company || company.data?.status !== 'active') {
    const failure = new Error('Company is unavailable.');
    failure.status = 404;
    throw failure;
  }
  return { membership, platformExploration, company };
}

async function requireVehicleImageAdmin(userId, companyId) {
  const access = await requireVehicleImageAccess(userId, companyId);
  const platformSuperAdmin = isPlatformSuperAdmin(userId);
  const role = access.membership?.data?.role || '';
  if (!platformSuperAdmin && !['owner', 'admin'].includes(role)) {
    const failure = new Error('Only company administrators can upload a shared vehicle image.');
    failure.status = 403;
    throw failure;
  }
  return { ...access, platformSuperAdmin };
}

async function getVehicleImageCapabilities({ userId, input }) {
  const companyId = String(input.companyId || '').trim();
  const access = await requireVehicleImageAccess(userId, companyId);
  const platformSuperAdmin = isPlatformSuperAdmin(userId);
  const role = access.membership?.data?.role || '';
  return {
    ok: true,
    canUpload: platformSuperAdmin || ['owner', 'admin'].includes(role),
    canForceRefresh: platformSuperAdmin,
    isPlatformSuperAdmin: platformSuperAdmin,
  };
}

function vehicleImageMimeInfo(contentType, urlOrName = '') {
  const mimeType = String(contentType || '').split(';')[0].trim().toLowerCase();
  const allowed = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };
  const extension = allowed[mimeType];
  if (!extension) return null;
  return { mimeType: mimeType === 'image/jpg' ? 'image/jpeg' : mimeType, extension };
}

function normalizeImageSearchText(value) {
  return String(value || '').normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function toRomanNumeral(value) {
  const pairs = [
    [10, 'x'], [9, 'ix'], [5, 'v'], [4, 'iv'], [1, 'i'],
  ];
  let remaining = Number(value);
  if (!Number.isInteger(remaining) || remaining < 1 || remaining > 20) return '';
  let result = '';
  for (const [amount, numeral] of pairs) {
    while (remaining >= amount) {
      result += numeral;
      remaining -= amount;
    }
  }
  return result;
}

function vehicleImageModelAliases(model) {
  const aliases = new Set([normalizeImageSearchText(model)]);
  const match = String(model).trim().match(/^(.*?)[\s-]+(\d{1,2})$/);
  if (match) {
    const roman = toRomanNumeral(Number(match[2]));
    if (roman) {
      aliases.add(normalizeImageSearchText(`${match[1]} ${roman}`));
      aliases.add(normalizeImageSearchText(`${match[1]} generation ${match[2]}`));
    }
  }
  return [...aliases].filter(Boolean);
}

const VEHICLE_IMAGE_COLOR_TERMS = {
  white: ['white', 'blanc', 'blanche', 'blanco'],
  black: ['black', 'noir', 'noire', 'negro'],
  silver: ['silver', 'argent', 'argente', 'grey metallic', 'gris metallise'],
  grey: ['grey', 'gray', 'gris', 'anthracite', 'charcoal'],
  blue: ['blue', 'bleu', 'bleue', 'azul'],
  red: ['red', 'rouge', 'rojo'],
};

function vehicleImageCandidateMatches(candidate, { make, model, year, color }) {
  const text = normalizeImageSearchText([
    candidate.title, candidate.description, candidate.tags,
  ].filter(Boolean).join(' '));
  const normalizedMake = normalizeImageSearchText(make);
  const makeMatches = normalizedMake.split(' ').filter(Boolean)
    .every(token => text.includes(token));
  const aliases = vehicleImageModelAliases(model);
  const modelMatches = aliases.some(alias => text.includes(alias));
  const yearText = String(year);
  // A generation-specific model alias (for example Clio 5 / Clio V) is a
  // valid model-year proxy. Otherwise the requested year must be present in
  // the indexed metadata. The year is also part of the provider query.
  const hasGenerationAlias = aliases.length > 1 &&
    aliases.slice(1).some(alias => text.includes(alias));
  const yearMatches = text.includes(yearText) || hasGenerationAlias;
  const colorTerms = VEHICLE_IMAGE_COLOR_TERMS[color] || [];
  const colorMatches = color === 'original' ||
    colorTerms.some(term => text.includes(normalizeImageSearchText(term)));
  return makeMatches && modelMatches && yearMatches && colorMatches;
}

function isAllowedCommercialImageLicense(value) {
  const license = normalizeImageSearchText(value);
  return [
    'cc0', 'pdm', 'public domain', 'public domain mark',
    'cc by', 'cc by sa', 'by', 'by sa',
  ].includes(license) ||
    license.startsWith('cc0 ') ||
    license.startsWith('cc by ') ||
    license.startsWith('cc by sa ');
}

function cleanImageMetadata(value) {
  return String(value || '')
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

function isSafeExternalHttpsUrl(value) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || !url.hostname) return false;
    const hostname = url.hostname.toLowerCase();
    if (
      hostname === 'localhost' ||
      hostname.endsWith('.localhost') ||
      hostname.endsWith('.local') ||
      hostname.endsWith('.internal') ||
      hostname.startsWith('[') ||
      /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(hostname) ||
      /^127\./.test(hostname) ||
      /^10\./.test(hostname) ||
      /^192\.168\./.test(hostname) ||
      /^169\.254\./.test(hostname) ||
      hostname === '[::1]' ||
      hostname === 'metadata.google.internal'
    ) return false;
    return true;
  } catch (_) {
    return false;
  }
}

async function downloadExternalVehicleImage(url) {
  let currentUrl = url;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    if (!isSafeExternalHttpsUrl(currentUrl)) {
      throw Object.assign(new Error('Vehicle image provider returned an unsafe URL.'), { status: 502 });
    }
    const response = await fetch(currentUrl, {
      redirect: 'manual',
      signal: AbortSignal.timeout(20000),
      headers: { 'User-Agent': 'Parcoto Vehicle Image Service/1.0' },
    });
    if ([301, 302, 303, 307, 308].includes(response.status)) {
      const location = response.headers.get('location');
      if (!location) throw Object.assign(new Error('Image redirect has no location.'), { status: 502 });
      currentUrl = new URL(location, currentUrl).toString();
      continue;
    }
    if (!response.ok) {
      throw Object.assign(new Error(`Image download failed (${response.status}).`), { status: response.status });
    }
    const info = vehicleImageMimeInfo(response.headers.get('content-type'), currentUrl);
    if (!info) throw Object.assign(new Error('Provider did not return a supported image format.'), { status: 415 });
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (!bytes.length || bytes.length > 5 * 1024 * 1024) {
      throw Object.assign(new Error('Vehicle image is empty or exceeds the 5 MB storage limit.'), { status: 413 });
    }
    return { bytes, ...info };
  }
  throw Object.assign(new Error('Too many redirects while downloading vehicle image.'), { status: 502 });
}

async function searchWikimediaVehicleImage(criteria) {
  const aliases = vehicleImageModelAliases(criteria.model);
  const colourTerms = VEHICLE_IMAGE_COLOR_TERMS[criteria.color] || [];
  const query = [
    criteria.make,
    aliases[0],
    String(criteria.year),
    colourTerms[0] || '',
    'car',
  ].filter(Boolean).join(' ');
  const params = new URLSearchParams({
    action: 'query',
    generator: 'search',
    gsrsearch: query,
    gsrnamespace: '6',
    gsrlimit: '30',
    prop: 'imageinfo',
    iiprop: 'url|extmetadata',
    iiurlwidth: '1200',
    format: 'json',
    formatversion: '2',
  });
  const response = await fetch(`https://commons.wikimedia.org/w/api.php?${params}`, {
    signal: AbortSignal.timeout(15000),
    headers: { 'User-Agent': 'Parcoto Vehicle Image Service/1.0 (https://parcoto.com)' },
  });
  if (!response.ok) throw new Error(`Wikimedia Commons search failed (${response.status}).`);
  const payload = await response.json();
  const pages = payload.query?.pages || [];
  const candidates = [];
  for (const page of pages) {
    const image = page.imageinfo?.[0];
    if (!image) continue;
    const metadata = image.extmetadata || {};
    const license = cleanImageMetadata(metadata.LicenseShortName?.value || '');
    if (!isAllowedCommercialImageLicense(license)) continue;
    const description = cleanImageMetadata(metadata.ImageDescription?.value || '');
    const title = cleanImageMetadata(metadata.ObjectName?.value || page.title || '');
    const candidate = {
      title: `${page.title || ''} ${title}`,
      description,
      tags: '',
      imageUrl: image.thumburl || image.url,
      sourceUrl: image.descriptionurl || `https://commons.wikimedia.org/wiki/${encodeURIComponent(page.title || '')}`,
      license,
      attribution: cleanImageMetadata(
        metadata.Attribution?.value ||
        metadata.Credit?.value ||
        `${cleanImageMetadata(metadata.Artist?.value || 'Auteur non indiqué')} — ${license}`
      ).slice(0, 1000),
      source: 'wikimedia_commons',
    };
    if (!candidate.imageUrl || !isSafeExternalHttpsUrl(candidate.imageUrl)) continue;
    if (vehicleImageCandidateMatches(candidate, criteria)) candidates.push(candidate);
  }
  return candidates.slice(0, 5);
}

async function searchOpenverseVehicleImage(criteria) {
  const aliases = vehicleImageModelAliases(criteria.model);
  const colourTerms = VEHICLE_IMAGE_COLOR_TERMS[criteria.color] || [];
  const query = [
    criteria.make,
    aliases[0],
    String(criteria.year),
    colourTerms[0] || '',
    'car',
  ].filter(Boolean).join(' ');
  const params = new URLSearchParams({
    q: query,
    license_type: 'commercial,modification',
    extension: 'jpg,jpeg,png,webp',
    page_size: '20',
    mature: 'false',
  });
  const response = await fetch(`https://api.openverse.org/v1/images/?${params}`, {
    signal: AbortSignal.timeout(15000),
    headers: { 'User-Agent': 'Parcoto Vehicle Image Service/1.0' },
  });
  if (!response.ok) throw new Error(`Openverse search failed (${response.status}).`);
  const payload = await response.json();
  const candidates = [];
  for (const item of payload.results || []) {
    const license = String(item.license || '').toLowerCase();
    if (!['cc0', 'pdm', 'by', 'by-sa'].includes(license)) continue;
    const candidate = {
      title: item.title || '',
      description: item.description || '',
      tags: (item.tags || []).map(tag => tag.name || '').join(' '),
      imageUrl: item.url || '',
      sourceUrl: item.foreign_landing_url || item.detail_url || '',
      license: `${license.toUpperCase()}${item.license_version ? ` ${item.license_version}` : ''}`,
      licenseUrl: String(item.license_url || ''),
      attribution: String(item.attribution || `${item.title || 'Image'} — ${item.creator || 'Auteur non indiqué'} — ${license}`).slice(0, 1000),
      source: 'openverse',
    };
    if (
      candidate.imageUrl &&
      isSafeExternalHttpsUrl(candidate.imageUrl) &&
      vehicleImageCandidateMatches(candidate, criteria)
    ) candidates.push(candidate);
  }
  return candidates.slice(0, 5);
}

async function persistVehicleImage({
  rowId, cacheKey, make, model, year, color, candidate, bytes, mimeType,
  extension, userId,
}) {
  const previous = await getVehicleImageCacheRow(rowId);
  const fileId = randomUUID().replace(/-/g, '').slice(0, 32);
  const fileName = `${slugify(make)}-${slugify(model)}-${year}-${color}-${fileId.slice(0, 6)}.${extension}`;
  await uploadVehicleImage(fileId, fileName, bytes, mimeType);
  const imageUrl = `${endpoint}/storage/buckets/${VEHICLE_IMAGE_BUCKET}/files/${fileId}/view?project=${encodeURIComponent(projectId)}`;
  try {
    await saveVehicleImageCacheRow(rowId, {
      cacheKey, make, model, modelYear: year, color,
      imageUrl, fileId,
      source: candidate.source,
      sourceUrl: String(candidate.sourceUrl || '').slice(0, 2048),
      license: String(candidate.license || 'Unspecified').slice(0, 100),
      licenseUrl: String(candidate.licenseUrl || '').slice(0, 2048),
      attribution: String(candidate.attribution || '').slice(0, 1000),
      uploadedBy: candidate.source === 'manual_upload' ? userId : '',
      generation: null,
      status: 'found',
      lastCheckedAt: new Date().toISOString(),
    });
  } catch (failure) {
    await deleteVehicleImageFile(fileId);
    throw failure;
  }
  const oldFileId = previous?.data?.fileId || (previous?.data?.imageUrl ? rowId : null);
  if (oldFileId && oldFileId !== fileId) await deleteVehicleImageFile(oldFileId);
  return {
    ok: true, found: true, source: candidate.source, imageUrl, fileId,
    make, model, year, color,
    requestedColor: color, colorFallback: false,
    license: candidate.license || null,
    licenseUrl: candidate.licenseUrl || null,
    attribution: candidate.attribution || null,
    sourceUrl: candidate.sourceUrl || null,
  };
}

async function searchFreeVehicleImageSources(criteria, log) {
  const providers = [
    ['wikimedia_commons', searchWikimediaVehicleImage],
    ['openverse', searchOpenverseVehicleImage],
  ];
  for (const [name, search] of providers) {
    try {
      const candidates = await search(criteria);
      for (const candidate of candidates) {
        try {
          const downloaded = await downloadExternalVehicleImage(candidate.imageUrl);
          return { candidate, downloaded };
        } catch (failure) {
          log(`Vehicle image candidate rejected provider=${name} reason=${failure.message}`);
        }
      }
      log(`Vehicle image provider returned no strict match provider=${name}`);
    } catch (failure) {
      log(`Vehicle image provider unavailable provider=${name} reason=${failure.message}`);
    }
  }
  return null;
}

async function resolveVehicleImage({ userId, input, log }) {
  const companyId = String(input.companyId || '').trim();
  await requireVehicleImageAccess(userId, companyId);

  const forceRefresh = input.forceRefresh === true;
  if (forceRefresh) requirePlatformSuperAdmin(userId);

  const make = String(input.make || '').trim().slice(0, 100);
  const model = String(input.model || '').trim().slice(0, 120);
  const year = Number.parseInt(input.year, 10);
  const currentYear = new Date().getUTCFullYear();
  if (!make || !model || !Number.isInteger(year) || year < 1886 || year > currentYear + 2) {
    const failure = new Error('Valid make, model and model year are required.');
    failure.status = 400;
    throw failure;
  }

  const color = normalizeVehicleImageColor(input.color);
  const cacheKey = vehicleImageCacheKey(make, model, year, color);
  const rowId = cacheKey.slice(0, 32);
  const now = new Date();
  const cached = await getVehicleImageCacheRow(rowId);
  const cachedFound = cached?.data?.cacheKey === cacheKey &&
    cached.data.status === 'found' && cached.data.imageUrl;

  if (!forceRefresh && cachedFound) {
    return {
      ok: true,
      found: true,
      source: cached.data.source || 'shared_cache',
      fromSharedCache: true,
      imageUrl: cached.data.imageUrl,
      fileId: cached.data.fileId || rowId,
      make: cached.data.make,
      model: cached.data.model,
      year: cached.data.modelYear,
      color: cached.data.color || color,
      requestedColor: color,
      colorFallback: color !== 'original' && cached.data.color === 'original',
      generation: cached.data.generation || null,
      license: cached.data.license || null,
      licenseUrl: cached.data.licenseUrl || null,
      attribution: cached.data.attribution || null,
      sourceUrl: cached.data.sourceUrl || null,
    };
  }

  if (!forceRefresh && cached?.data?.cacheKey === cacheKey &&
      cached.data.status === 'not_found') {
    const checkedAt = Date.parse(cached.data.lastCheckedAt || '');
    if (Number.isFinite(checkedAt) &&
        now.getTime() - checkedAt < VEHICLE_IMAGE_NEGATIVE_TTL_MS) {
      return { ok: true, found: false, source: 'shared_cache', reason: 'not_found' };
    }
  }

  const criteria = { make, model, year, color };
  const freeResult = await searchFreeVehicleImageSources(criteria, log);
  if (freeResult) {
    const saved = await persistVehicleImage({
      rowId, cacheKey, make, model, year, color,
      candidate: freeResult.candidate,
      bytes: freeResult.downloaded.bytes,
      mimeType: freeResult.downloaded.mimeType,
      extension: freeResult.downloaded.extension,
      userId,
    });
    return { ...saved, replacementFound: forceRefresh };
  }

  // CarImagesAPI is deliberately the last provider. Its free plan adds a
  // visible watermark; keep it as a compatibility fallback while Parcoto is
  // in development, and do not make it a mandatory dependency.
  const apiKey = process.env.CARIMAGES_API_KEY;
  const apiSecret = process.env.CARIMAGES_API_SECRET;
  const currentSource = String(cached?.data?.source || '');
  const shouldTryCarImages = !forceRefresh || !cachedFound ||
    currentSource === '' || currentSource === 'carimages';
  if (apiKey && apiSecret && shouldTryCarImages) {
    try {
      const signedUrl = createCarImagesSignedUrl({
        make, model, year, color, apiKey, apiSecret,
      });
      const imageResponse = await fetch(signedUrl, {
        redirect: 'manual',
        signal: AbortSignal.timeout(20000),
      });
      if (imageResponse.status === 302) {
        const actualColor = String(
          imageResponse.headers.get('x-ci-color') || color
        ).toLowerCase();
        const location = imageResponse.headers.get('location');
        let cdnUrl;
        try { cdnUrl = new URL(location || ''); } catch (_) { cdnUrl = null; }
        if (!cdnUrl || cdnUrl.protocol !== 'https:' ||
            cdnUrl.hostname !== 'cdn.carimagesapi.com') {
          throw new Error('CarImagesAPI returned an unexpected image CDN location.');
        }
        const downloaded = await downloadExternalVehicleImage(location);
        const candidate = {
          source: 'carimages',
          sourceUrl: location,
          license: 'CarImagesAPI terms',
          attribution: 'CarImagesAPI',
        };
        const saved = await persistVehicleImage({
          rowId, cacheKey, make, model, year,
          color: actualColor, candidate,
          bytes: downloaded.bytes,
          mimeType: downloaded.mimeType,
          extension: downloaded.extension,
          userId,
        });
        const colorFallback = color !== 'original' && actualColor === 'original';
        return { ...saved, colorFallback, requestedColor: color, replacementFound: forceRefresh };
      }
      if (imageResponse.status === 404) {
        log('CarImagesAPI returned no image for the requested vehicle configuration.');
      } else {
        const body = await imageResponse.text().catch(() => '');
        log(`CarImagesAPI image request failed status=${imageResponse.status} body=${body.slice(0, 300)}`);
      }
    } catch (failure) {
      log(`CarImagesAPI fallback failed: ${failure.message}`);
    }
  } else {
    log('CarImagesAPI fallback skipped: credentials are not configured.');
  }

  if (forceRefresh && cachedFound) {
    log(`Forced vehicle image refresh found no better result; keeping current image row=${rowId}`);
    return {
      ok: true,
      found: true,
      source: cached.data.source || 'shared_cache',
      fromSharedCache: true,
      imageUrl: cached.data.imageUrl,
      fileId: cached.data.fileId || rowId,
      make: cached.data.make,
      model: cached.data.model,
      year: cached.data.modelYear,
      color: cached.data.color || color,
      requestedColor: color,
      colorFallback: color !== 'original' && cached.data.color === 'original',
      replacementFound: false,
      license: cached.data.license || null,
      licenseUrl: cached.data.licenseUrl || null,
      attribution: cached.data.attribution || null,
      sourceUrl: cached.data.sourceUrl || null,
      reason: 'replacement_not_found',
    };
  }

  if (!cachedFound) {
    await saveVehicleImageCacheRow(rowId, {
      cacheKey, make, model, modelYear: year, color,
      status: 'not_found',
      lastCheckedAt: new Date().toISOString(),
    });
  }
  return {
    ok: true,
    found: false,
    source: 'none',
    reason: 'no_matching_licensed_image',
    canUpload: true,
  };
}

async function uploadCustomVehicleImage({ userId, input }) {
  const companyId = String(input.companyId || '').trim();
  await requireVehicleImageAdmin(userId, companyId);

  const make = String(input.make || '').trim().slice(0, 100);
  const model = String(input.model || '').trim().slice(0, 120);
  const year = Number.parseInt(input.year, 10);
  const currentYear = new Date().getUTCFullYear();
  const color = normalizeVehicleImageColor(input.color);
  if (!make || !model || !Number.isInteger(year) ||
      year < 1886 || year > currentYear + 2) {
    const failure = new Error('Valid make, model, model year and color are required.');
    failure.status = 400;
    throw failure;
  }

  const cacheKey = vehicleImageCacheKey(make, model, year, color);
  const rowId = cacheKey.slice(0, 32);
  const cached = await getVehicleImageCacheRow(rowId);
  if (cached?.data?.cacheKey === cacheKey &&
      cached.data.status === 'found' && cached.data.imageUrl) {
    const failure = new Error('An image already exists for this model, year and color.');
    failure.status = 409;
    throw failure;
  }
  if (cached?.data?.cacheKey !== cacheKey || cached.data?.status !== 'not_found') {
    const failure = new Error('Run the automatic image search before adding a manual photo.');
    failure.status = 409;
    throw failure;
  }

  const mimeType = String(input.mimeType || '').toLowerCase().trim();
  const info = vehicleImageMimeInfo(mimeType);
  if (!info) {
    const failure = new Error('Only JPEG, PNG and WebP images are accepted.');
    failure.status = 415;
    throw failure;
  }
  const encoded = String(input.imageBase64 || '').replace(/^data:image\/[a-z0-9.+-]+;base64,/i, '');
  if (!encoded || encoded.length > 7 * 1024 * 1024) {
    const failure = new Error('Image payload is empty or too large.');
    failure.status = 413;
    throw failure;
  }
  const bytes = Buffer.from(encoded, 'base64');
  if (!bytes.length || bytes.length > 5 * 1024 * 1024) {
    const failure = new Error('Image must not exceed 5 MB.');
    failure.status = 413;
    throw failure;
  }

  const candidate = {
    source: 'manual_upload',
    sourceUrl: '',
    license: 'Uploaded by Parcoto company administrator',
    licenseUrl: '',
    attribution: String(input.attribution || 'Photo fournie par l’administrateur de l’entreprise').slice(0, 1000),
  };
  return persistVehicleImage({
    rowId, cacheKey, make, model, year, color,
    candidate, bytes,
    mimeType: info.mimeType,
    extension: info.extension,
    userId,
  });
}
export default async (context) => requestContext.run(
  { apiKey: context.req.headers['x-appwrite-key'] },
  async () => {
    const { req, res, log, error } = context;
    try {
    if (!projectId || !requestContext.getStore()?.apiKey) {
      return json(res, 500, { ok: false, message: 'Function configuration is incomplete.' });
    }
    const { userId } = await authenticate(req);
    const input = req.bodyJson || {};
    const action = input.action;
    const now = new Date().toISOString();

    if (action === 'platform_resolve') {
      // This is a capability probe called by every account during login.
      // A normal tenant user must receive a successful "not a platform admin"
      // result, not HTTP 403: Appwrite Functions SDKs may throw on non-2xx
      // executions and abort the regular tenant-membership resolution.
      if (!isPlatformSuperAdmin(userId)) {
        return json(res, 200, { ok: true, userId, isPlatformSuperAdmin: false });
      }
      try {
        await restorePlatformExploration(userId);
      } catch (failure) {
        // Never lock the platform Super Admin out of the control center because
        // tenant-exploration cleanup failed. Keep the error visible in logs.
        log(`Platform exploration restoration deferred for ${userId}: ${failure.message}`);
      }
      return json(res, 200, { ok: true, userId, isPlatformSuperAdmin: true });
    }

    if (action === 'platform_return_to_platform') {
      requirePlatformSuperAdmin(userId);
      let restored = false;
      try {
        restored = await restorePlatformExploration(userId);
      } catch (failure) {
        log(`Platform return cleanup deferred for ${userId}: ${failure.message}`);
      }
      return json(res, 200, { ok: true, restored, userId, isPlatformSuperAdmin: true });
    }

    if (action === 'platform_select_company') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      if (!companyId) {
        return json(res, 400, { ok: false, message: 'companyId is required.' });
      }
      const company = await getCompany(companyId);
      if (!company) {
        return json(res, 404, { ok: false, message: 'Company not found.' });
      }
      let teamId = String(company.data?.teamId || '').trim();
      // Legacy companies may predate dedicated tenant teams. Provision the
      // team on first open instead of making the super admin perform a
      // separate recovery operation.
      // Close any previous exploration before changing tenant membership.
      await restorePlatformExploration(userId);
      if (!teamId) {
        teamId = `pc-${companyId.replace(/[^a-zA-Z0-9._-]/g, '-').slice(0, 32)}`;
        try {
          await createCompanyTeam(teamId, `Parcoto — ${company.data?.name || companyId}`);
        } catch (failure) {
          if (failure.status !== 409) throw failure;
          const existingTeam = await appwrite(`/teams/${encodeURIComponent(teamId)}`);
          if (!existingTeam?.$id) throw failure;
        }
        await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`, {
          method: 'PATCH',
          body: { data: { teamId, updatedAt: now } },
        });
        const companyMemberships = await listRows(MEMBERSHIPS, {
          method: 'equal', attribute: 'companyId', values: [companyId],
        });
        for (const membership of companyMemberships.filter(item => item.data?.status === 'active')) {
          let memberName = '';
          try {
            const account = await appwrite(`/users/${encodeURIComponent(membership.data.userId)}`);
            memberName = account.name || '';
          } catch (_) {}
          await syncTeamMembership(
            teamId, membership.data.userId, membership.data.role || 'viewer', memberName,
          );
        }
        company.data = { ...(company.data || {}), teamId };
      }

      let accountName = '';
      try {
        const account = await appwrite(`/users/${encodeURIComponent(userId)}`);
        accountName = account.name || '';
      } catch (_) {}

      const existingMembership = (await listTeamMemberships(teamId))
        .find(item => item.userId === userId) || null;
      const prefs = await readUserPrefs(userId);
      await writeUserPrefs(userId, {
        ...prefs,
        parcotoPlatformExploration: {
          companyId,
          teamId,
          existed: Boolean(existingMembership),
          previousRoles: existingMembership?.roles || [],
          startedAt: now,
        },
      });

      try {
        const profile = await ensureCompanyProfile(
          companyId, company.data?.name || companyId, teamId, now,
        );
        const aclPreparation = await prepareCompanyRows(companyId, teamId);
        const membership = await syncTeamMembership(teamId, userId, 'admin', accountName);
        return json(res, 200, {
          ok: true,
          company: {
            companyId: company.$id,
            name: company.data?.name || '',
            slug: company.data?.slug || '',
            teamId,
            profileRowId: profile.rowId,
          },
          teamMembershipId: membership.$id,
          aclPreparation,
          entitlement: await getEntitlement(companyId),
        });
      } catch (failure) {
        await restorePlatformExploration(userId);
        throw failure;
      }
    }

    if (action === 'vehicle_image_resolve') {
      const result = await resolveVehicleImage({ userId, input, log });
      return json(res, 200, result);
    }

    if (action === 'vehicle_image_capabilities') {
      const result = await getVehicleImageCapabilities({ userId, input });
      return json(res, 200, result);
    }

    if (action === 'vehicle_image_upload') {
      const result = await uploadCustomVehicleImage({ userId, input });
      return json(res, 201, result);
    }

    if (action === 'resolve') {
      const rows = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'userId', values: [userId],
      });
      log(`Tenant resolve diagnostic user=${userId} membershipRows=${rows.length} rows=${JSON.stringify(rows.map(row => ({ id: row.$id, userId: row.data?.userId, companyId: row.data?.companyId, status: row.data?.status }))) }`);
      const memberships = [];
      for (const row of rows.filter(item => item.data?.status === 'active')) {
        const company = await getCompany(row.data.companyId);
        log(`Tenant resolve company diagnostic companyId=${row.data.companyId} found=${Boolean(company)} status=${company?.data?.status || 'missing'} teamId=${company?.data?.teamId || ''}`);
        if (company && company.data?.status === 'active') {
          const teamId = String(company.data?.teamId || '').trim();
          const entitlement = await getEntitlement(company.$id);
          const profile = teamId
            ? await ensureCompanyProfile(
                company.$id,
                company.data?.name || company.$id,
                teamId,
                now,
              )
            : null;
          const accessState = teamId
            ? await enforceCompanyAccessState(company, entitlement)
            : { licenseActive: false, aclEnforced: false };
          memberships.push({
            companyId: company.$id,
            companyName: company.data.name,
            companySlug: company.data.slug,
            teamId,
            profileRowId: profile?.rowId || '',
            role: row.data.role,
            membershipId: row.$id,
            entitlement,
            licenseActive: accessState.licenseActive,
            aclEnforced: accessState.aclEnforced,
          });
        }
      }
      return json(res, 200, { ok: true, userId, memberships });
    }

    if (action === 'platform_list_companies') {
      requirePlatformSuperAdmin(userId);
      const companies = await listAllRows(COMPANIES);
      const result = [];
      for (const company of companies) {
        const entitlement = await getEntitlement(company.$id);
        const memberships = await listRows(MEMBERSHIPS, {
          method: 'equal', attribute: 'companyId', values: [company.$id],
        });
        const profiles = await listRows(COMPANY_PROFILE, {
          method: 'equal', attribute: 'companyId', values: [company.$id],
        });
        const profile = profiles[0]?.data || {};
        result.push({
          companyId: company.$id,
          name: company.data?.name || '',
          slug: company.data?.slug || '',
          status: company.data?.status || 'active',
          createdAt: company.data?.createdAt || '',
          profile: {
            legalName: profile.nom || '',
            address: profile.adresse || '',
            phone: profile.telephone || '',
            email: profile.email || '',
            nif: profile.nif || '',
            nis: profile.nis || '',
            rc: profile.rc || '',
            art: profile.art || '',
            description: profile.description || '',
          },
          entitlement,
          activeUsers: memberships.filter(item => item.data?.status === 'active').length,
        });
      }
      const canCreateCompany =
        process.env.TENANT_COMPANY_CREATION_ENABLED === 'true';
      return json(res, 200, {
        ok: true,
        companies: result,
        capabilities: {
          canCreateCompany,
          createCompanyReason: canCreateCompany
            ? ''
            : 'La création est temporairement verrouillée tant que l’isolation des anciennes données et permissions n’est pas terminée.',
        },
      });
    }


    if (action === 'platform_update_company') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      if (!companyId) {
        return json(res, 400, { ok: false, message: 'companyId is required.' });
      }
      const company = await getCompany(companyId);
      if (!company) return json(res, 404, { ok: false, message: 'Company not found.' });

      const name = input.name === undefined
        ? String(company.data?.name || '')
        : String(input.name || '').trim();
      const slug = input.slug === undefined
        ? String(company.data?.slug || '')
        : slugify(input.slug);
      const status = input.status === undefined
        ? String(company.data?.status || 'active')
        : String(input.status);
      if (name.length < 2 || name.length > 160 || slug.length < 2 ||
          !['active', 'suspended'].includes(status)) {
        return json(res, 400, { ok: false, message: 'Invalid company name, identifier or status.' });
      }
      const duplicateSlugs = await listRows(COMPANIES, {
        method: 'equal', attribute: 'slug', values: [slug],
      });
      if (duplicateSlugs.some(row => row.$id !== companyId)) {
        return json(res, 409, { ok: false, message: 'This company identifier is already used.' });
      }

      const entitlementKeys = [
        'startsAt', 'expiresAt', 'maxUsers', 'maxVehicles', 'maxEmployees',
        'maxDrivers', 'maxSites', 'priceAmount', 'billingCycle', 'currency', 'notes',
      ];
      const hasEntitlementChanges = entitlementKeys.some(key =>
        Object.prototype.hasOwnProperty.call(input, key)
      );
      const previousEntitlement = await getEntitlement(companyId);
      let nextEntitlement = previousEntitlement;
      if (hasEntitlementChanges) {
        const startsAt = new Date(input.startsAt || previousEntitlement?.startsAt || now);
        const defaultExpiry = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
        const expiresAt = new Date(
          input.expiresAt || previousEntitlement?.expiresAt || defaultExpiry.toISOString()
        );
        const values = {
          maxUsers: Number(input.maxUsers ?? previousEntitlement?.maxUsers ?? 5),
          maxVehicles: Number(input.maxVehicles ?? previousEntitlement?.maxVehicles ?? 50),
          maxEmployees: Number(input.maxEmployees ?? previousEntitlement?.maxEmployees ?? 20),
          maxDrivers: Number(input.maxDrivers ?? previousEntitlement?.maxDrivers ?? 20),
          maxSites: Number(input.maxSites ?? previousEntitlement?.maxSites ?? 1),
          priceAmount: Number(input.priceAmount ?? previousEntitlement?.priceAmount ?? 0),
        };
        const billingCycle = String(input.billingCycle ?? previousEntitlement?.billingCycle ?? 'monthly');
        const currency = String(input.currency ?? previousEntitlement?.currency ?? 'DZD').toUpperCase();
        if (!Number.isFinite(startsAt.getTime()) ||
            !Number.isFinite(expiresAt.getTime()) || expiresAt <= startsAt ||
            !Object.values(values).every(Number.isSafeInteger) ||
            Object.values(values).some(value => value < 0) ||
            values.maxUsers < 1 ||
            !['monthly', 'quarterly', 'yearly', 'custom'].includes(billingCycle) ||
            !/^[A-Z]{3}$/.test(currency)) {
          return json(res, 400, { ok: false, message: 'Invalid licence dates, quotas or billing values.' });
        }
        nextEntitlement = {
          companyId,
          startsAt: startsAt.toISOString(),
          expiresAt: expiresAt.toISOString(),
          ...values,
          currency,
          billingCycle,
          notes: String(input.notes ?? previousEntitlement?.notes ?? '').trim().slice(0, 2000),
          createdAt: previousEntitlement?.createdAt || now,
          updatedAt: now,
        };
      }

      let entitlementWritten = false;
      if (hasEntitlementChanges && nextEntitlement) {
        if (previousEntitlement) {
          await appwrite(`/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${encodeURIComponent(companyId)}`, {
            method: 'PATCH', body: { data: nextEntitlement },
          });
        } else {
          await createRow(
            ENTITLEMENTS,
            companyId,
            nextEntitlement,
            companyEntitlementPermissions(company.data?.teamId || ''),
          );
        }
        entitlementWritten = true;
      }

      try {
        await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`, {
          method: 'PATCH',
          body: { data: { name, slug, status, updatedAt: now } },
        });
        if (company.data?.teamId) {
          await prepareCompanyRows(companyId, company.data.teamId);
        }
      } catch (failure) {
        try {
          await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`, {
            method: 'PATCH',
            body: {
              data: {
                name: company.data?.name || name,
                slug: company.data?.slug || slug,
                status: company.data?.status || 'active',
                updatedAt: now,
              },
            },
          });
        } catch (_) {}
        if (entitlementWritten) {
          try {
            if (previousEntitlement) {
              await appwrite(`/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${encodeURIComponent(companyId)}`, {
                method: 'PATCH', body: { data: previousEntitlement },
              });
            } else {
              await appwrite(`/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${encodeURIComponent(companyId)}`, {
                method: 'DELETE',
              });
            }
          } catch (_) {}
        }
        throw failure;
      }

      try {
        const profiles = await listRows(COMPANY_PROFILE, {
          method: 'equal', attribute: 'companyId', values: [companyId],
        });
        const profileInput = {
          nom: ['companyLegalName', 60],
          adresse: ['address', 100],
          telephone: ['phone', 15],
          email: ['companyEmail', 254],
          nif: ['nif', 30],
          nis: ['nis', 30],
          rc: ['rc', 30],
          art: ['art', 30],
          description: ['description', 80],
        };
        const profilePatch = {};
        for (const [field, [inputKey, maxLength]] of Object.entries(profileInput)) {
          if (Object.prototype.hasOwnProperty.call(input, inputKey)) {
            const value = String(input[inputKey] ?? '').trim().slice(0, maxLength);
            // Appwrite email columns reject empty strings. Omit an unset optional
            // company email instead of sending "" to the database.
            if (field !== 'email' || value) profilePatch[field] = value;
          }
        }
        const existingProfile = profiles[0];
        if (!existingProfile && company.data?.teamId) {
          const profile = await ensureCompanyProfile(
            companyId, name, company.data.teamId, now, {
              name: profilePatch.nom || name,
              address: profilePatch.adresse || '',
              phone: profilePatch.telephone || '',
              email: profilePatch.email || '',
              nif: profilePatch.nif || '',
              nis: profilePatch.nis || '',
              rc: profilePatch.rc || '',
              art: profilePatch.art || '',
              description: profilePatch.description || '',
            },
          );
          log(`Company profile provisioned for ${companyId}: ${profile.rowId}`);
        } else if (existingProfile) {
          if (!Object.prototype.hasOwnProperty.call(profilePatch, 'nom') &&
              existingProfile.data?.nom === company.data?.name) {
            profilePatch.nom = name.slice(0, 60);
          }
          if (Object.keys(profilePatch).length) {
            const nextProfile = { ...existingProfile.data, ...profilePatch };
            profilePatch.search = [
              nextProfile.nom, nextProfile.adresse, nextProfile.telephone,
              nextProfile.email, nextProfile.nif, nextProfile.nis,
              nextProfile.rc, nextProfile.art,
            ].filter(Boolean).join(' ').slice(0, 400);
            await appwrite(
              `/tablesdb/${DATABASE_ID}/tables/${COMPANY_PROFILE}/rows/${encodeURIComponent(existingProfile.$id)}`,
              { method: 'PATCH', body: { data: profilePatch } },
            );
          }
        }
      } catch (failure) {
        log(`Company profile sync skipped for ${companyId}: ${failure.message}`);
      }

      return json(res, 200, {
        ok: true,
        company: { companyId, name, slug, status, entitlement: nextEntitlement },
      });
    }

    if (action === 'platform_list_company_admins') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      if (!companyId) {
        return json(res, 400, { ok: false, message: 'companyId is required.' });
      }
      const company = await getCompany(companyId);
      if (!company) return json(res, 404, { ok: false, message: 'Company not found.' });
      const rows = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'companyId', values: [companyId],
      });
      const administrators = [];
      for (const row of rows.filter(item =>
        ['owner', 'admin'].includes(item.data?.role)
      )) {
        let account = null;
        try {
          account = await appwrite(`/users/${encodeURIComponent(row.data.userId)}`);
        } catch (_) {}
        administrators.push({
          membershipId: row.$id,
          userId: row.data.userId,
          name: account?.name || '',
          email: account?.email || '',
          role: row.data.role || 'admin',
          status: row.data.status || 'active',
          isPlatformSuperAdmin: isPlatformSuperAdmin(row.data.userId),
          createdAt: row.data.createdAt || '',
        });
      }
      return json(res, 200, { ok: true, companyId, administrators });
    }

    if (action === 'platform_add_company_admin') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      const name = String(input.name || '').trim();
      const email = String(input.email || '').trim().toLowerCase();
      const password = String(input.password || '');
      if (!companyId || name.length < 2 || name.length > 100 ||
          !/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)) {
        return json(res, 400, { ok: false, message: 'Invalid company, administrator name or email.' });
      }
      const company = await getCompany(companyId);
      if (!company || company.data?.status !== 'active') {
        return json(res, 404, { ok: false, message: 'Active company not found.' });
      }
      const teamId = String(company.data?.teamId || '').trim();
      if (!teamId) {
        return json(res, 409, { ok: false, message: 'Company team is not provisioned.' });
      }

      const search = new URLSearchParams({ search: email, limit: '25' });
      const matchingUsers = await appwrite(`/users?${search.toString()}`);
      const existingUser = (matchingUsers.users || []).find(item =>
        item.email?.toLowerCase() === email
      ) || null;
      if (!existingUser && password.length < 8) {
        return json(res, 400, { ok: false, message: 'A password of at least 8 characters is required for a new account.' });
      }

      const allMemberships = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'companyId', values: [companyId],
      });
      const activeMemberships = allMemberships.filter(item => item.data?.status === 'active');
      const existingMembership = existingUser
        ? allMemberships.find(item => item.data?.userId === existingUser.$id) || null
        : null;
      if (existingMembership?.data?.status === 'active' &&
          ['admin', 'owner'].includes(existingMembership.data?.role)) {
        return json(res, 409, { ok: false, message: 'This account is already an administrator of the company.' });
      }
      const entitlement = await getEntitlement(companyId);
      if (!existingMembership || existingMembership.data?.status !== 'active') {
        if (entitlement && activeMemberships.length >= Number(entitlement.maxUsers || 0)) {
          return json(res, 409, { ok: false, message: 'The company has reached its licensed user limit.' });
        }
      }

      const targetUserId = existingUser?.$id || crypto.randomUUID();
      let accountCreated = false;
      let teamMembershipChanged = false;
      let previousRole = existingMembership?.data?.status === 'active'
        ? (existingMembership.data.role || null)
        : null;
      try {
        if (!existingUser) {
          await appwrite('/users', {
            method: 'POST',
            body: { userId: targetUserId, email, password, name },
          });
          accountCreated = true;
        } else if (name && existingUser.name !== name) {
          await appwrite(`/users/${encodeURIComponent(targetUserId)}/name`, {
            method: 'PATCH', body: { name },
          });
        }

        await syncTeamMembership(teamId, targetUserId, 'admin', name);
        teamMembershipChanged = true;
        const membershipId = existingMembership?.$id || crypto.randomUUID();
        const membershipData = {
          companyId,
          userId: targetUserId,
          role: 'admin',
          status: 'active',
          invitedBy: userId,
          createdAt: existingMembership?.data?.createdAt || now,
          updatedAt: now,
        };
        if (existingMembership) {
          await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
            method: 'PATCH', body: { data: membershipData },
          });
        } else {
          await createRow(MEMBERSHIPS, membershipId, membershipData);
        }
      } catch (failure) {
        if (teamMembershipChanged) {
          try {
            if (previousRole) await syncTeamMembership(teamId, targetUserId, previousRole);
            else await removeTeamMembership(teamId, targetUserId);
          } catch (_) {}
        }
        if (accountCreated) {
          try { await appwrite(`/users/${encodeURIComponent(targetUserId)}`, { method: 'DELETE' }); } catch (_) {}
        }
        throw failure;
      }
      return json(res, 201, {
        ok: true,
        companyId,
        userId: targetUserId,
        email,
        role: 'admin',
        reusedExistingAccount: Boolean(existingUser),
      });
    }

    if (action === 'platform_update_company_admin') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      const membershipId = String(input.membershipId || '').trim();
      const name = String(input.name || '').trim();
      if (!companyId || !membershipId || name.length < 2 || name.length > 100) {
        return json(res, 400, { ok: false, message: 'Invalid company, membership or administrator name.' });
      }
      const membership = await appwrite(
        `/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`
      );
      if (membership.data?.companyId !== companyId ||
          !['owner', 'admin'].includes(membership.data?.role) ||
          membership.data?.status !== 'active') {
        return json(res, 404, { ok: false, message: 'Active company administrator not found.' });
      }
      await appwrite(`/users/${encodeURIComponent(membership.data.userId)}/name`, {
        method: 'PATCH', body: { name },
      });
      await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
        method: 'PATCH', body: { data: { updatedAt: now } },
      });
      return json(res, 200, { ok: true, userId: membership.data.userId, name });
    }

    if (action === 'platform_revoke_company_admin') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      const membershipId = String(input.membershipId || '').trim();
      if (!companyId || !membershipId) {
        return json(res, 400, { ok: false, message: 'companyId and membershipId are required.' });
      }
      const company = await getCompany(companyId);
      if (!company) return json(res, 404, { ok: false, message: 'Company not found.' });
      const membership = await appwrite(
        `/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`
      );
      const targetUserId = String(membership.data?.userId || '');
      if (membership.data?.companyId !== companyId ||
          !['owner', 'admin'].includes(membership.data?.role) ||
          membership.data?.status !== 'active') {
        return json(res, 404, { ok: false, message: 'Active company administrator not found.' });
      }
      if (membership.data?.role === 'owner' ||
          (company.data?.ownerUserId && company.data.ownerUserId === targetUserId)) {
        return json(res, 403, { ok: false, message: 'The company owner cannot be revoked. Transfer ownership first.' });
      }
      if (isPlatformSuperAdmin(targetUserId)) {
        return json(res, 403, { ok: false, message: 'A global platform administrator cannot be removed from a company here.' });
      }
      const administrators = (await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'companyId', values: [companyId],
      })).filter(item =>
        item.data?.status === 'active' &&
        ['owner', 'admin'].includes(item.data?.role)
      );
      if (administrators.length <= 1) {
        return json(res, 409, { ok: false, message: 'At least one active company administrator must remain.' });
      }
      let teamMembershipRemoved = false;
      if (company.data?.teamId) {
        teamMembershipRemoved = await removeTeamMembership(
          company.data.teamId,
          targetUserId,
        );
      }
      try {
        await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
          method: 'PATCH', body: { data: { status: 'revoked', updatedAt: now } },
        });
      } catch (failure) {
        if (teamMembershipRemoved && company.data?.teamId) {
          try {
            await syncTeamMembership(
              company.data.teamId,
              targetUserId,
              membership.data.role || 'admin',
            );
          } catch (_) {}
        }
        throw failure;
      }
      return json(res, 200, { ok: true, companyId, userId: targetUserId });
    }

    if (action === 'platform_provision_company_team') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '');
      if (!companyId) return json(res, 400, { ok: false, message: 'companyId is required.' });
      const company = await getCompany(companyId);
      if (!company || company.data?.status !== 'active') {
        return json(res, 404, { ok: false, message: 'Active company not found.' });
      }
      let teamId = String(company.data?.teamId || '').trim();
      if (!teamId) {
        teamId = `pc-${companyId.replace(/[^a-zA-Z0-9._-]/g, '-').slice(0, 32)}`;
        try {
          await createCompanyTeam(teamId, `Parcoto — ${company.data?.name || companyId}`);
        } catch (failure) {
          if (failure.status !== 409) throw failure;
          const existingTeam = await appwrite(`/teams/${encodeURIComponent(teamId)}`);
          if (!existingTeam?.$id) throw failure;
        }
        await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`, {
          method: 'PATCH',
          body: { data: { teamId, updatedAt: now } },
        });
      }
      const memberships = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'companyId', values: [companyId],
      });
      const synchronized = [];
      for (const membership of memberships.filter(item => item.data?.status === 'active')) {
        const role = membership.data.role || 'viewer';
        let accountName = '';
        try {
          const account = await appwrite(`/users/${encodeURIComponent(membership.data.userId)}`);
          accountName = account.name || '';
        } catch (_) {}
        const teamMembership = await syncTeamMembership(
          teamId, membership.data.userId, role, accountName,
        );
        synchronized.push({ userId: membership.data.userId, teamMembershipId: teamMembership.$id, roles: teamMembership.roles });
      }
      return json(res, 200, { ok: true, companyId, teamId, synchronized });
    }


    if (action === 'platform_audit_company_rows') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      if (!companyId) {
        return json(res, 400, { ok: false, message: 'companyId is required.' });
      }
      const company = await getCompany(companyId);
      if (!company) {
        return json(res, 404, { ok: false, message: 'Company not found.' });
      }
      const teamId = String(company.data?.teamId || '').trim();
      const params = new URLSearchParams();
      params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
      const tableResult = await appwrite(
        `/tablesdb/${DATABASE_ID}/tables?${params.toString()}`
      );
      const tables = [];
      for (const table of tableResult.tables || []) {
        const columns = table.columns || [];
        const hasCompanyId = columns.some(column => column.key === 'companyId');
        const serverManaged = [
          COMPANIES, MEMBERSHIPS, ENTITLEMENTS,
        ].includes(table.$id);
        // These tables intentionally do not belong to a tenant: the vehicle
        // type catalogue is shared reference data, users stores global account
        // profiles, and the remaining tables are legacy/platform settings.
        const platformGlobal = [
          '6537960246d5b0e1ab77', 'users', 'trialdate', 'admin_keys', 'limits',
        ].includes(table.$id);
        const scope = serverManaged
          ? 'platform_managed'
          : hasCompanyId
            ? 'tenant'
            : platformGlobal
              ? 'platform_global'
              : 'unclassified';
        const tablePermissions = table.$permissions || [];
        const isUnsafeTablePermission = permission =>
          /^(read|update|delete)\(/.test(permission) ||
          (/^create\(/.test(permission) &&
            !/^create\("team:[^"]+\/(admin|manager)"\)$/.test(permission));
        const broadPermissions = tablePermissions.filter(isUnsafeTablePermission);
        let rows = [];
        if (hasCompanyId) {
          rows = await listAllRows(table.$id);
        }
        const companyRows = hasCompanyId
          ? rows.filter(row => row.data?.companyId === companyId)
          : [];
        tables.push({
          tableId: table.$id,
          name: table.name || table.$id,
          rowSecurity: table.rowSecurity === true,
          hasCompanyId,
          serverManaged,
          scope,
          totalRows: hasCompanyId ? rows.length : null,
          companyRows: companyRows.length,
          unassignedRows: hasCompanyId
            ? rows.filter(row => !row.data?.companyId).length
            : null,
          otherCompanyRows: hasCompanyId
            ? rows.filter(row => row.data?.companyId && row.data.companyId !== companyId).length
            : null,
          rowsWithoutPermissions: serverManaged ? 0 : companyRows.filter(row =>
            !(row.$permissions || []).length
          ).length,
          rowsWithLegacyPermissions: companyRows.filter(row =>
            (row.$permissions || []).some(isUnsafeTablePermission)
          ).length,
          broadTablePermissions: broadPermissions,
          includedInCurrentPreparation: TENANT_TABLE_IDS.includes(table.$id),
          requiresClassification: scope === 'unclassified',
        });
      }
      const tenantTables = tables.filter(table =>
        table.hasCompanyId && !table.serverManaged
      );
      return json(res, 200, {
        ok: true,
        readOnly: true,
        companyId,
        teamId,
        summary: {
          tables: tables.length,
          tenantScopedTables: tenantTables.length,
          tablesWithoutRowSecurity: tables.filter(table => !table.rowSecurity).length,
          tablesWithBroadPermissions: tables.filter(table =>
            table.broadTablePermissions.length > 0
          ).length,
          rowsWithoutCompanyId: tenantTables.reduce(
            (total, table) => total + table.unassignedRows, 0
          ),
          companyRowsWithoutPermissions: tenantTables.reduce(
            (total, table) => total + table.rowsWithoutPermissions, 0
          ),
          tablesRequiringClassification: tables.filter(
            table => table.requiresClassification
          ).length,
        },
        tables,
      });
    }

    if (action === 'platform_lock_quota_table_creates') {
      requirePlatformSuperAdmin(userId);
      const tables = await lockQuotaTableCreatePermissions();
      return json(res, 200, {
        ok: true,
        tables,
        note: 'Direct table-level create permissions are removed for quota-controlled resources. Creates must use the quota transaction endpoint.',
      });
    }

    if (action === 'tenant_create_resource') {
      const result = await createQuotaResource(userId, input);
      return json(res, result.created ? 201 : 200, { ok: true, ...result });
    }

    if (action === 'tenant_delete_resource') {
      const result = await deleteQuotaResource(userId, input);
      return json(res, 200, { ok: true, ...result });
    }

    if (action === 'platform_prepare_company_rows') {
      requirePlatformSuperAdmin(userId);
      const companyId = String(input.companyId || '').trim();
      if (!companyId) {
        return json(res, 400, { ok: false, message: 'companyId is required.' });
      }
      const company = await getCompany(companyId);
      if (!company) {
        return json(res, 404, { ok: false, message: 'Company not found.' });
      }
      const teamId = String(company.data?.teamId || '').trim();
      if (!teamId) {
        return json(res, 409, { ok: false, message: 'Company team is not provisioned.' });
      }
      const preparation = await prepareCompanyRows(companyId, teamId);
      return json(res, 200, {
        ok: true,
        ...preparation,
        note: 'Tenant row ACLs are prepared. Existing global table permissions are preserved; only company-scoped create permissions are added.',
      });
    }

    if (action === 'create_company') {
      requirePlatformSuperAdmin(userId);
      if (process.env.TENANT_COMPANY_CREATION_ENABLED !== 'true') {
        return json(res, 403, { ok: false, message: 'Company provisioning is disabled until tenant data provisioning and isolation are verified.' });
      }
      const name = String(input.name || '').trim();
      const slug = slugify(input.slug || name);
      const adminName = String(input.adminName || '').trim();
      const adminEmail = String(input.adminEmail || '').trim().toLowerCase();
      const adminPassword = String(input.adminPassword || '');
      const companyProfile = {
        name: String(input.companyLegalName || name).trim(),
        address: String(input.address || '').trim(),
        phone: String(input.phone || '').trim(),
        email: String(input.companyEmail || '').trim(),
        nif: String(input.nif || '').trim(),
        nis: String(input.nis || '').trim(),
        rc: String(input.rc || '').trim(),
        art: String(input.art || '').trim(),
        description: String(input.description || '').trim(),
      };
      const startsAt = new Date(input.startsAt || now);
      const expiresAt = new Date(input.expiresAt || '');
      const maxUsers = Number(input.maxUsers);
      const maxVehicles = Number(input.maxVehicles);
      const maxEmployees = Number(input.maxEmployees);
      const maxDrivers = Number(input.maxDrivers);
      const maxSites = Number(input.maxSites);
      const priceAmount = Number(input.priceAmount || 0);
      const billingCycle = String(input.billingCycle || 'monthly');
      const currency = String(input.currency || 'DZD').toUpperCase();
      const userSearch = new URLSearchParams({ search: adminEmail, limit: '25' });
      const matchingUsers = await appwrite(`/users?${userSearch.toString()}`);
      const existingAdmin = (matchingUsers.users || []).find(item => item.email?.toLowerCase() === adminEmail) || null;
      if (name.length < 2 || name.length > 160 || slug.length < 2 ||
          adminName.length < 2 || !adminEmail || (!existingAdmin && adminPassword.length < 8) ||
          companyProfile.name.length > 60 || companyProfile.address.length > 100 ||
          companyProfile.phone.length > 15 || companyProfile.email.length > 254 ||
          companyProfile.nif.length > 30 || companyProfile.nis.length > 30 ||
          companyProfile.rc.length > 30 || companyProfile.art.length > 30 ||
          companyProfile.description.length > 80 ||
          !Number.isFinite(startsAt.getTime()) || !Number.isFinite(expiresAt.getTime()) ||
          expiresAt <= startsAt ||
          ![maxUsers, maxVehicles, maxEmployees, maxDrivers, maxSites, priceAmount].every(Number.isSafeInteger) ||
          [maxUsers, maxVehicles, maxEmployees, maxDrivers, maxSites, priceAmount].some(value => value < 0) ||
          maxUsers < 1 || !['monthly', 'quarterly', 'yearly', 'custom'].includes(billingCycle) ||
          !/^[A-Z]{3}$/.test(currency)) {
        return json(res, 400, { ok: false, message: 'Invalid company, administrator, license or quota values.' });
      }
      const existing = await listRows(COMPANIES, { method: 'equal', attribute: 'slug', values: [slug] });
      if (existing.length) return json(res, 409, { ok: false, message: 'This company identifier is already used.' });

      const companyId = crypto.randomUUID();
      const adminUserId = existingAdmin?.$id || crypto.randomUUID();
      const membershipId = crypto.randomUUID();
      const entitlement = {
        companyId, startsAt: startsAt.toISOString(), expiresAt: expiresAt.toISOString(),
        maxUsers, maxVehicles, maxEmployees, maxDrivers, maxSites,
        priceAmount, currency, billingCycle,
        notes: String(input.notes || '').trim().slice(0, 2000),
        createdAt: now, updatedAt: now,
      };
      const teamId = `pc-${companyId.slice(0, 32)}`;
      let accountCreated = false;
      let companyCreated = false;
      let entitlementCreated = false;
      let teamCreated = false;
      let profileCreated = false;
      let profileRowId = null;
      try {
        if (!existingAdmin) {
          await appwrite('/users', {
            method: 'POST',
            body: { userId: adminUserId, email: adminEmail, password: adminPassword, name: adminName },
          });
          accountCreated = true;
        }
        await createRow(COMPANIES, companyId, {
          name, slug, status: 'active', ownerUserId: adminUserId, teamId, createdAt: now, updatedAt: now,
        });
        companyCreated = true;
        await createCompanyTeam(teamId, `Parcoto — ${name}`);
        teamCreated = true;
        const profile = await ensureCompanyProfile(
          companyId,
          name,
          teamId,
          now,
          companyProfile,
        );
        profileCreated = profile.created;
        profileRowId = profile.rowId;
        await createRow(
          ENTITLEMENTS,
          companyId,
          entitlement,
          companyEntitlementPermissions(teamId),
        );
        entitlementCreated = true;
        await prepareCompanyRows(companyId, teamId);
        await syncTeamMembership(teamId, adminUserId, 'owner', adminName);
        await createRow(MEMBERSHIPS, membershipId, {
          companyId, userId: adminUserId, role: 'admin', status: 'active',
          invitedBy: userId, createdAt: now, updatedAt: now,
        });
      } catch (failure) {
        if (entitlementCreated) {
          try { await appwrite(`/tablesdb/${DATABASE_ID}/tables/${ENTITLEMENTS}/rows/${companyId}`, { method: 'DELETE' }); } catch (_) {}
        }
        if (profileCreated && profileRowId) {
          try { await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANY_PROFILE}/rows/${encodeURIComponent(profileRowId)}`, { method: 'DELETE' }); } catch (_) {}
        }
        if (teamCreated) {
          try { await appwrite(`/teams/${encodeURIComponent(teamId)}`, { method: 'DELETE' }); } catch (_) {}
        }
        if (companyCreated) {
          try { await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${companyId}`, { method: 'DELETE' }); } catch (_) {}
        }
        if (accountCreated) {
          try { await appwrite(`/users/${adminUserId}`, { method: 'DELETE' }); } catch (_) {}
        }
        throw failure;
      }
      return json(res, 201, {
        ok: true,
        company: { companyId, name, slug, status: 'active', entitlement },
        administrator: { userId: adminUserId, email: adminEmail, role: 'admin', reusedExistingAccount: Boolean(existingAdmin) },
      });
    }

    if (action === 'list_members') {
      const companyId = String(input.companyId || '');
      if (!companyId) return json(res, 400, { ok: false, message: 'companyId is required.' });
      await requireCompanyAdmin(userId, companyId);
      const rows = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'companyId', values: [companyId],
      });
      const members = [];
      for (const row of rows) {
        if (row.data?.status === 'revoked') continue;
        let account = null;
        try {
          account = await appwrite(`/users/${encodeURIComponent(row.data.userId)}`);
        } catch (failure) {
          log(`Could not resolve account ${row.data.userId}: ${failure.message}`);
        }
        members.push({
          membershipId: row.$id,
          isCurrentUser: row.data.userId === userId,
          userId: row.data.userId,
          name: account?.name || '',
          email: account?.email || '',
          role: row.data.role,
          status: row.data.status,
          createdAt: row.data.createdAt,
        });
      }
      return json(res, 200, { ok: true, companyId, members });
    }

    if (action === 'add_member') {
      const companyId = String(input.companyId || '');
      const email = String(input.email || '').trim().toLowerCase();
      const role = String(input.role || 'employee');
      if (!companyId || !email || !['admin', 'manager', 'employee', 'viewer'].includes(role)) {
        return json(res, 400, { ok: false, message: 'Invalid companyId, email or role.' });
      }
      await requireCompanyAdmin(userId, companyId);
      if (role === 'admin') {
        return json(res, 403, { ok: false, message: 'Company administrators cannot create or promote other administrators.' });
      }
      const company = await getCompany(companyId);
      if (!company?.data?.teamId) {
        return json(res, 409, { ok: false, message: 'Company team is not provisioned. Ask the platform administrator to provision it first.' });
      }
      const entitlement = await getEntitlement(companyId);
      if (entitlement) {
        const existingMembers = await listRows(MEMBERSHIPS, {
          method: 'equal', attribute: 'companyId', values: [companyId],
        });
        const activeCount = existingMembers.filter(item => item.data?.status === 'active').length;
        if (activeCount >= Number(entitlement.maxUsers || 0)) {
          return json(res, 409, { ok: false, message: 'The company has reached its licensed user limit.' });
        }
      }
      const search = new URLSearchParams({ search: email, limit: '25' });
      const users = await appwrite(`/users?${search.toString()}`);
      const target = (users.users || []).find(item => item.email?.toLowerCase() === email);
      if (!target) return json(res, 404, { ok: false, message: 'No Parcoto account exists for this email yet.' });

      const existing = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'userId', values: [target.$id],
      });
      const current = existing.find(row => row.data?.companyId === companyId);
      if (current && current.data?.status !== 'revoked') {
        return json(res, 409, { ok: false, message: 'This user is already a member of the company.' });
      }
      const membershipId = current?.$id || crypto.randomUUID();
      const data = {
        companyId, userId: target.$id, role, status: 'active',
        invitedBy: userId, createdAt: current?.data?.createdAt || now, updatedAt: now,
      };
      await syncTeamMembership(company.data.teamId, target.$id, role, target.name || '');
      try {
        if (current) {
          await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
            method: 'PATCH', body: { data },
          });
        } else {
          await createRow(MEMBERSHIPS, membershipId, data);
        }
      } catch (failure) {
        try { await removeTeamMembership(company.data.teamId, target.$id); } catch (_) {}
        throw failure;
      }
      return json(res, 201, { ok: true, membershipId, userId: target.$id, email, role });
    }

    if (action === 'change_role') {
      const companyId = String(input.companyId || '');
      const membershipId = String(input.membershipId || '');
      const role = String(input.role || '');
      if (!companyId || !membershipId || !['manager', 'employee', 'viewer'].includes(role)) {
        return json(res, 400, { ok: false, message: 'Invalid companyId, membershipId or role.' });
      }
      const caller = await requireCompanyAdmin(userId, companyId);
      const target = normalizeRow(await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`));
      if (target.data?.companyId !== companyId || target.data?.role === 'owner' || target.data?.status === 'revoked') {
        return json(res, 403, { ok: false, message: 'The target membership cannot be changed.' });
      }
      if (target.data?.role === 'admin') {
        return json(res, 403, { ok: false, message: 'Company administrator accounts are managed only by the platform.' });
      }
      const company = await getCompany(companyId);
      if (company?.data?.teamId) {
        await syncTeamMembership(company.data.teamId, target.data.userId, role);
      }
      await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
        method: 'PATCH', body: { data: { role, updatedAt: now } },
      });
      return json(res, 200, { ok: true });
    }

    if (action === 'revoke') {
      const companyId = String(input.companyId || '');
      const membershipId = String(input.membershipId || '');
      if (!companyId || !membershipId) {
        return json(res, 400, { ok: false, message: 'companyId and membershipId are required.' });
      }
      const caller = await requireCompanyAdmin(userId, companyId);
      const target = normalizeRow(await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`));
      if (target.data?.companyId !== companyId || target.data?.role === 'owner' || target.data?.userId === userId || target.data?.status === 'revoked') {
        return json(res, 403, { ok: false, message: 'The target membership cannot be revoked.' });
      }
      if (target.data?.role === 'admin') {
        return json(res, 403, { ok: false, message: 'Company administrator accounts are managed only by the platform.' });
      }
      const company = await getCompany(companyId);
      if (company?.data?.teamId) {
        await removeTeamMembership(company.data.teamId, target.data.userId);
      }
      await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
        method: 'PATCH', body: { data: { status: 'revoked', updatedAt: now } },
      });
      return json(res, 200, { ok: true });
    }

    return json(res, 400, { ok: false, message: 'Unknown action.' });
  } catch (failure) {
    error(failure.stack || failure.message);
    return json(res, failure.status || 500, {
      ok: false,
      message: failure.status && failure.status < 500 ? failure.message : 'Internal tenant service error.',
    });
  }
  }
);
