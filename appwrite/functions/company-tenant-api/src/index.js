const DATABASE_ID = '6531ad112080ae3b14a7';
const MEMBERSHIPS = 'company_memberships';
const COMPANIES = 'companies';

const endpoint = (process.env.APPWRITE_FUNCTION_API_ENDPOINT || 'https://fra.cloud.appwrite.io/v1').replace(/\/$/, '');
const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
const apiKey = process.env.APPWRITE_FUNCTION_API_KEY;

function json(res, status, body) {
  return res.json(body, status);
}

function queryUrl(tableId, query) {
  const params = new URLSearchParams();
  params.append('queries[]', JSON.stringify(query));
  params.set('limit', '100');
  return `${endpoint}/tablesdb/${DATABASE_ID}/tables/${tableId}/rows?${params.toString()}`;
}

async function appwrite(path, { method = 'GET', body, jwt } = {}) {
  const headers = { 'X-Appwrite-Project': projectId };
  if (jwt) headers['X-Appwrite-JWT'] = jwt;
  else headers['X-Appwrite-Key'] = apiKey;
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  const response = await fetch(`${endpoint}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(payload.message || `Appwrite request failed (${response.status})`);
    error.status = response.status;
    throw error;
  }
  return payload;
}

async function authenticate(req) {
  const jwt = req.headers['x-appwrite-user-jwt'];
  if (!jwt) {
    const error = new Error('Authentication required.');
    error.status = 401;
    throw error;
  }
  const account = await appwrite('/account', { jwt });
  return { userId: account.$id, jwt };
}

async function listRows(tableId, query) {
  const result = await appwrite(queryUrl(tableId, query).replace(endpoint, ''));
  return result.rows || [];
}

async function getCompany(companyId) {
  try {
    return await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`);
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

async function activeMembership(userId, companyId) {
  const rows = await listRows(MEMBERSHIPS, {
    method: 'equal', attribute: 'userId', values: [userId],
  });
  return rows.find(row =>
    row.companyId === companyId && row.status === 'active'
  ) || null;
}

async function requireCompanyAdmin(userId, companyId) {
  const membership = await activeMembership(userId, companyId);
  if (!membership || !['owner', 'admin'].includes(membership.role)) {
    const error = new Error('You are not authorized to administer this company.');
    error.status = 403;
    throw error;
  }
  const company = await getCompany(companyId);
  if (!company || company.status !== 'active') {
    const error = new Error('Company is unavailable.');
    error.status = 404;
    throw error;
  }
  return membership;
}

export default async ({ req, res, log, error }) => {
  try {
    if (!projectId || !apiKey) {
      return json(res, 500, { ok: false, message: 'Function configuration is incomplete.' });
    }
    const { userId } = await authenticate(req);
    const input = req.bodyJson || {};
    const action = input.action;

    if (action === 'resolve') {
      const memberships = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'userId', values: [userId],
      });
      const active = memberships.filter(row => row.status === 'active');
      const resolved = [];
      for (const membership of active) {
        const company = await getCompany(membership.companyId);
        if (company && company.status === 'active') {
          resolved.push({
            companyId: company.$id,
            companyName: company.name,
            companySlug: company.slug,
            role: membership.role,
            membershipId: membership.$id,
          });
        }
      }
      return json(res, 200, { ok: true, userId, memberships: resolved });
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
        if (row.status === 'revoked') continue;
        let account = null;
        try {
          account = await appwrite(`/users/${encodeURIComponent(row.userId)}`);
        } catch (e) {
          log(`Could not resolve account ${row.userId}: ${e.message}`);
        }
        members.push({
          membershipId: row.$id,
          userId: row.userId,
          name: account?.name || '',
          email: account?.email || '',
          role: row.role,
          status: row.status,
          createdAt: row.createdAt,
        });
      }
      return json(res, 200, { ok: true, companyId, members });
    }

    if (action === 'change_role') {
      const companyId = String(input.companyId || '');
      const membershipId = String(input.membershipId || '');
      const role = String(input.role || '');
      if (!companyId || !membershipId || !['admin', 'manager', 'employee', 'viewer'].includes(role)) {
        return json(res, 400, { ok: false, message: 'Invalid companyId, membershipId or role.' });
      }
      const caller = await requireCompanyAdmin(userId, companyId);
      const target = await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`);
      if (target.companyId !== companyId || target.role === 'owner') {
        return json(res, 403, { ok: false, message: 'The target membership cannot be changed.' });
      }
      if (caller.role !== 'owner' && role === 'admin') {
        return json(res, 403, { ok: false, message: 'Only the owner can promote an administrator.' });
      }
      await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
        method: 'PATCH',
        body: { data: { role, updatedAt: new Date().toISOString() } },
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
      const target = await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`);
      if (target.companyId !== companyId || target.role === 'owner' || target.userId === userId) {
        return json(res, 403, { ok: false, message: 'The target membership cannot be revoked.' });
      }
      if (caller.role !== 'owner' && target.role === 'admin') {
        return json(res, 403, { ok: false, message: 'Only the owner can revoke an administrator.' });
      }
      await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
        method: 'PATCH',
        body: { data: { status: 'revoked', updatedAt: new Date().toISOString() } },
      });
      return json(res, 200, { ok: true });
    }

    return json(res, 400, { ok: false, message: 'Unknown action.' });
  } catch (e) {
    error(e.stack || e.message);
    return json(res, e.status || 500, {
      ok: false,
      message: e.status && e.status < 500 ? e.message : 'Internal tenant service error.',
    });
  }
};
