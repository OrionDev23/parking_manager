# Parcoto Company Tenant API

Appwrite Function: `company-tenant-api` (Node.js 22).

## Runtime configuration

Uses Appwrite-provided function variables:
- `APPWRITE_FUNCTION_API_ENDPOINT`
- `APPWRITE_FUNCTION_PROJECT_ID`
- `APPWRITE_FUNCTION_API_KEY` (secret; scopes: users.read, tables.read, rows.read, rows.write)

Database: `6531ad112080ae3b14a7` (Parking).

## Authenticated actions

Every request requires the Appwrite user JWT in `x-appwrite-user-jwt`. The function validates it against `/account`; the caller's user ID is never accepted from request JSON.

- `{ "action": "resolve" }`: active company memberships for the authenticated user.
- `{ "action": "create_company", "name": "...", "slug": "..." }`: create a company and make the caller its owner.
- `{ "action": "list_members", "companyId": "..." }`: owner/admin only.
- `{ "action": "add_member", "companyId": "...", "email": "...", "role": "employee" }`: owner/admin only; account must already exist. Only owner can grant admin.
- `{ "action": "change_role", "companyId": "...", "membershipId": "...", "role": "manager" }`: owner/admin only; owner role is immutable through this endpoint.
- `{ "action": "revoke", "companyId": "...", "membershipId": "..." }`: soft-revoke membership; never deletes the global Appwrite account.

Rows in `companies` and `company_memberships` have no direct client permissions. All tenant membership mutations go through this function.

## Important migration note

The existing legacy tenant key `essais` is also the fixed Appwrite project ID. It remains a legacy company identifier only for compatibility until all existing business rows are migrated. Do not assume the two identifiers are interchangeable in new code.
