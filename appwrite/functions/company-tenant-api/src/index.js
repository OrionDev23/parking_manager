const DATABASE_ID = '6531ad112080ae3b14a7';
const MEMBERSHIPS = 'company_memberships';
const COMPANIES = 'companies';

const endpoint = (process.env.APPWRITE_FUNCTION_API_ENDPOINT || 'https://fra.cloud.appwrite.io/v1').replace(/\/$/, '');
const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
const apiKey = process.env.APPWRITE_FUNCTION_API_KEY;

function json(res, status, body) {
  return res.json(body, status);
}

function queryPath(tableId, query) {
  const params = new URLSearchParams();
  params.append('queries[]', JSON.stringify(query));
  params.set('limit', '100');
  return `/tablesdb/${DATABASE_ID}/tables/${tableId}/rows?${params.toString()}`;
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

async function listRows(tableId, query) {
  const result = await appwrite(queryPath(tableId, query));
  return result.rows || [];
}

async function getCompany(companyId) {
  try {
    return await appwrite(`/tablesdb/${DATABASE_ID}/tables/${COMPANIES}/rows/${encodeURIComponent(companyId)}`);
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
  if (!membership || !['owner', 'admin'].includes(membership.data.role)) {
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
      const rows = await listRows(MEMBERSHIPS, {
        method: 'equal', attribute: 'userId', values: [userId],
      });
      const memberships = [];
      for (const row of rows.filter(item => item.data?.status === 'active')) {
        const companyId = row.data.companyId;
        const company = await getCompany(companyId);
        if (company && company.data?.status === 'active') {
          memberships.push({
            companyId: company.$id,
            companyName: company.data.name,
            companySlug: company.data.slug,
            role: row.data.role,
            membershipId: row.$id,
          });
        }
      }
      return json(res, 200, { ok: true, userId, memberships });
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

    if (action === 'change_role') {
      const companyId = String(input.companyId || '');
      const membershipId = String(input.membershipId || '');
      const role = String(input.role || '');
      if (!companyId || !membershipId || !['admin', 'manager', 'employee', 'viewer'].includes(role)) {
        return json(res, 400, { ok: false, message: 'Invalid companyId, membershipId or role.' });
      }
      const caller = await requireCompanyAdmin(userId, companyId);
      const target = await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`);
      if (target.data?.companyId !== companyId || target.data?.role === 'owner') {
        return json(res, 403, { ok: false, message: 'The target membership cannot be changed.' });
      }
      if (caller.data.role !== 'owner' && role === 'admin') {
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
      if (target.data?.companyId !== companyId || target.data?.role === 'owner' || target.data?.userId === userId) {
        return json(res, 403, { ok: false, message: 'The target membership cannot be revoked.' });
      }
      if (caller.data.role !== 'owner' && target.data?.role === 'admin') {
        return json(res, 403, { ok: false, message: 'Only the owner can revoke an administrator.' });
      }
      await appwrite(`/tablesdb/${DATABASE_ID}/tables/${MEMBERSHIPS}/rows/${encodeURIComponent(membershipId)}`, {
        method: 'PATCH',
        body: { data: { status: 'revoked', updatedAt: new Date().toISOString() } },
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
};
