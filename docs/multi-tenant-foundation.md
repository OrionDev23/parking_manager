# Parcoto multi-tenant foundation

## Appwrite resources

Project: `essais`  
Database: `Parking` (`6531ad112080ae3b14a7`)

- `companies`: tenant registry; no direct client permissions.
- `company_memberships`: user/company membership, role and status; no direct client permissions.
- Function: `company-tenant-api` (Node 22), intended to be the only client-facing path for tenant membership operations.

## Function actions

All requests require an authenticated Appwrite user JWT (the Appwrite Function runtime supplies `x-appwrite-user-jwt`).

- `{ "action": "resolve" }`: returns active memberships for the authenticated user.
- `{ "action": "list_members", "companyId": "..." }`: owner/admin only.
- `{ "action": "change_role", "companyId": "...", "membershipId": "...", "role": "manager|employee|viewer|admin" }`: owner/admin; only owner can promote an admin.
- `{ "action": "revoke", "companyId": "...", "membershipId": "..." }`: owner/admin; owner membership and self-revocation are blocked.

## Important migration rules

1. Do not infer a company owner from a legacy Appwrite team name.
2. Do not create memberships for legacy users until the real company/user mapping has been reviewed.
3. Keep legacy login active until the client calls `resolve` successfully and a migration mapping is approved.
4. Do not use Appwrite global Teams as the source of tenant roles.
5. Do not delete Appwrite accounts when removing a company membership.

## Deployment

The function source is in `appwrite/functions/company-tenant-api/src/index.js`. The Appwrite Function is created in project `essais`; upload a deployment from this directory and activate it only after a successful build and smoke test.
