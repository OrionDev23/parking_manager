# Company entitlements schema

This schema is required by the platform company administration UI and the
`company-tenant-api` Function. It is a proposed Appwrite TablesDB schema;
it has **not** been created in the live project.

## Table

- Database: `Parking` (`6531ad112080ae3b14a7`)
- Table ID: `company_entitlements`
- Row ID: the corresponding `companies.$id` (one entitlement record per company)
- Row security: enabled
- Table permissions: none (server Function only)

## Columns

| Key | Appwrite type | Required | Notes |
|---|---|---:|---|
| companyId | string (36) | yes | Must equal row ID and companies.$id |
| startsAt | datetime | yes | License start, UTC |
| expiresAt | datetime | yes | License expiry, UTC; strictly after startsAt |
| maxUsers | integer | yes | Minimum 1 |
| maxVehicles | integer | yes | 0 means no vehicles permitted; no unlimited sentinel yet |
| maxEmployees | integer | yes | 0 means no employees permitted |
| maxDrivers | integer | yes | 0 means no drivers permitted |
| maxSites | integer | yes | 0 means no sites permitted |
| priceAmount | integer | yes | Whole DZD integer amount (the UI currently labels this as DA) |
| currency | string (3) | yes | ISO 4217 code; currently DZD |
| billingCycle | string (16) | yes | monthly, quarterly, yearly, custom |
| notes | string (2000) | no | Commercial notes |
| createdAt | datetime | yes | UTC |
| updatedAt | datetime | yes | UTC |

Create an index on `companyId` if querying by that attribute. The current
Function reads entitlement rows by their deterministic row ID, so the row ID
is the primary lookup path.

## Function environment

Set the server-only environment variable:

- `PLATFORM_SUPER_ADMIN_IDS=999`

Keep `TENANT_COMPANY_CREATION_ENABLED` unset or false until the full tenant
data migration, server-side row authorization, entitlement enforcement and
restore/sync audit are complete. Never expose the Appwrite API key or this
allowlist in Flutter.

## Provisioning flow implemented in code

1. Authenticate the request through the Appwrite user JWT.
2. Compare the authenticated immutable user ID against the server-only
   super-admin allowlist.
3. Validate company identity, initial administrator credentials, license dates,
   quotas and billing metadata.
4. Create the Appwrite Auth account for the first company administrator.
5. Create the company registry row.
6. Create the entitlement row.
7. Create the first membership with role `admin`.
8. Roll back the newly created account and rows if a later step fails.

The platform API also exposes a global company list with active membership
counts. The Flutter screen is a management surface only; authorization remains
in the Function.

## Important implementation boundary

The quota values are currently stored and displayed, but are **not yet enforced**
against vehicle, driver, employee, site or user creation. Several legacy tables
do not yet have a reliable company key, so counting those records now would
produce incorrect billing decisions. Do not issue real customer contracts based
on enforcement claims until each resource is tenant-scoped and server-validated.

The current company creation action remains gated by
`TENANT_COMPANY_CREATION_ENABLED`. The new interface/API cannot create live
companies until the table is provisioned, the Function deployment is updated,
and the broader tenant isolation gate is explicitly cleared.
