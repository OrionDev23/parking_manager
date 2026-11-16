# Parcoto tenant data inventory

Audit date: 2026-11-16  
Appwrite project: `essais`  
Database: `Parking` (`6531ad112080ae3b14a7`)  
Observed tables: 30

This document records the live TablesDB schema and current access posture. Classification is an architectural recommendation, not a claim that the table has already been migrated.

## Executive findings

- Only `chauffeur` and `vehicle` among the legacy business tables currently expose both `companyId` and `siteId`.
- Their table-level `rowSecurity` is still disabled. Their table permissions still refer to global Appwrite Teams (`team:1`, `team:managers`).
- The remaining operational tables do not expose `companyId`; a client-side company filter cannot isolate their records.
- Most legacy business tables are accessible through global Appwrite Team permissions.
- `companies` and `company_memberships` are correctly server-managed: row security enabled, no table permissions.
- Do not enable row security or remove global Team permissions on legacy tables until existing rows have been migrated and per-row permissions have been provisioned and verified.

## Table classification

| Table ID | Current name | Recommended scope | Current tenant field | Migration priority |
|---|---|---|---|---|
| `6537960246d5b0e1ab77` | genre_vehicule | Global reference, pending product decision | No | Low |
| `6537d87b492c80f255e8` | chauffeur | Tenant-scoped | companyId, siteId | High |
| `users` | users | Global identity profile | No | System |
| `marque` | marque | Global reference, pending product decision | No | Low |
| `etat` | etat | Tenant-scoped operational state history | No | High |
| `doc_vehic` | doc_vehic | Tenant-scoped vehicle documents | No | High |
| `reparation` | reparation | Tenant-scoped repairs | No | High |
| `activity` | activity | Tenant-scoped audit/activity log | No | High |
| `chauf_disponibilite` | chauf_disponibilite | Tenant-scoped driver availability | No | High |
| `doc_chauffeur` | doc_chauffeur | Tenant-scoped driver documents | No | High |
| `prestataire` | prestataire | Tenant-scoped providers | No | High |
| `entreprise` | entreprise | Tenant-scoped company profile/settings | No | High |
| `planning` | planning | Tenant-scoped planning | No | High |
| `trialdate` | trialdate | System/licensing; replace legacy singleton semantics | No | System |
| `admin_keys` | admin_keys | System secrets; server-only | No | Critical |
| `limits` | limits | System/licensing; server-only | No | System |
| `backup` | backups | Tenant-scoped backup data | No | High |
| `options` | options | Tenant-scoped configurable catalog | No | Medium |
| `categories` | categories | Tenant-scoped inventory catalog | No | Medium |
| `partsbrands` | PartsBrands | Tenant-scoped inventory catalog unless intentionally shared | No | Medium |
| `parts` | Vehicle parts | Tenant-scoped inventory | No | High |
| `6531ad22153b2a49ca2c` | vehicle | Tenant-scoped | companyId, siteId | High |
| `storage` | storage | Tenant-scoped inventory movements/quantities | No | High |
| `fichereception` | FicheReception | Tenant-scoped vehicle reception | No | High |
| `clients` | clients | Tenant-scoped customers | No | High |
| `access_teams` | Access Teams | Tenant-scoped authorization configuration | companyId | High |
| `access_users` | User Access | Tenant-scoped authorization configuration | companyId | High |
| `fournisseurs` | Fournisseurs | Tenant-scoped suppliers | No | High |
| `companies` | Companies | Tenant registry | company record | Done (server-managed) |
| `company_memberships` | Company memberships | Tenant membership registry | companyId | Done (server-managed) |

The two reference tables `genre_vehicule` and `marque` are marked as global candidates only. Confirm whether each catalogue is shared platform-wide or customized by each company before implementing the scope.

## Access posture observed

### Server-managed tables

- `companies`: `rowSecurity=true`, no table-level permissions.
- `company_memberships`: `rowSecurity=true`, no table-level permissions.

These tables must continue to be accessed only through the tenant API Function.

### Legacy business tables

The following observations are security-relevant:

- `chauffeur` and `vehicle` have a `companyId` column, but `rowSecurity=false`.
- Most legacy business tables have no `companyId` column and `rowSecurity=false`.
- Existing table permissions refer to the project-wide Appwrite Teams `Admins` and `Managers`. Those Teams are not a tenant boundary.
- `users` is a global profile table and must not be confused with company membership.
- `admin_keys` exposes a table with a read permission for `team:1`; this is a system secret and should be moved behind a server-side API before the legacy global Team is retired.

## Safe migration sequence

1. Confirm global-vs-tenant scope for the two reference catalogues.
2. Add nullable `companyId` (and `siteId` only where needed) to tenant-scoped tables. Do not make the field required while legacy rows remain unmapped.
3. Backfill existing GTS rows using an audited migration. Do not infer tenant ownership from a row's creator unless that mapping is verified.
4. Update every read, create, update, delete, search, pagination, export, backup and sync path to enforce the active `companyId`.
5. Validate payload and row `companyId` consistency; reject mismatches.
6. Provision row-level permissions for existing and new records, using the tenant authorization model or a server-side data API.
7. Test with two companies and accounts that belong to only one company each, including direct API requests that bypass the UI.
8. Only after those tests pass, enable `rowSecurity` and remove global Team permissions from each migrated table.
9. Migrate `admin_keys`, `trialdate`, `limits` and backups to explicit server-side/system ownership.
10. Retire global Appwrite Team role checks after all old permission paths have been removed.

## Current limitations

- This audit inspected live table schemas, table-level permissions and row-security flags. It did not inspect every row in every table or prove the correctness of legacy ownership mapping.
- No live business-table permissions or row-security settings were changed by this audit.
- Flutter analysis and multi-company integration tests remain required before declaring the migration complete.

## Live row-count audit (read-only, 2026-11-16)

The Appwrite console TablesDB read operation was used to retrieve the exact `total` count for each legacy tenant table. Small samples were inspected for schema keys and ownership fields; no business values were copied into this report.

| Table | Rows | Tenant field present in schema | Sample ownership finding |
|---|---:|---|---|
| chauffeur | 183 | Yes | sampled rows use `companyId=essais` |
| vehicle | 8 | Yes | sampled rows use `companyId=essais` |
| etat | 4 | No | rows link by `vehicle` / `vehicleMat` |
| doc_vehic | 1 | No | row links by `vehicle` / `vehiclemat` |
| reparation | 0 | No | empty |
| activity | 70 | No | sample has `createdBy`, no tenant key |
| chauf_disponibilite | 0 | No | empty |
| doc_chauffeur | 0 | No | empty |
| prestataire | 0 | No | empty |
| entreprise | 1 | No | singleton company profile |
| planning | 10 | No | sample has `createdBy`, no tenant key |
| backup | 0 | No | empty |
| options | 4 | No | no tenant key |
| categories | 1 | No | no tenant key |
| partsbrands | 1 | No | no tenant key |
| parts | 2 | No | supplier references, no tenant key |
| storage | 0 | No | empty |
| fichereception | 1 | No | row links by vehicle fields, no tenant key |
| clients | 0 | No | empty |
| fournisseurs | 0 | No | empty |
| access_teams | 2 | Yes | both rows use `companyId=essais` |
| access_users | 4 | Yes | all four rows use `companyId=essais` |

Observed total: **292 rows** across the 22 tables classified as tenant-scoped. Of these, **95 rows** are in tables with no `companyId` column; the remaining 197 rows are in tables whose schema has a tenant field. This is a schema/count classification, not proof that every row has correct ownership. Only sample rows were inspected for the two large tables.

### Critical tenant registry inconsistency

The live `companies` table currently contains two active GTS records:

- `gts-guelma` (slug `gts-guelma`)
- `essais` (slug `gts-guelma-truck-service`)

The live `company_memberships` table contains eight active memberships: the same four user IDs (`999`, `1000`, `minpme`, `arrar`) are mapped once to each company ID. Meanwhile, the legacy `access_users`, `access_teams`, `chauffeur`, and `vehicle` samples still point to `companyId=essais`. The GTS duplicate is therefore not a cosmetic slug issue: the two company IDs currently describe overlapping access to the same legacy tenant.

**Do not revoke either membership, delete either company row, change any legacy companyId, or run a bulk backfill yet.** First decide which identifier is canonical. Based on current operational rows, `essais` is the identifier presently used by legacy data and authorization configuration. Renaming/re-keying to `gts-guelma` would require a coordinated migration of every dependent row and client preference; it is not safe to do implicitly.

The `users` profile table contains four profile rows, including `999`, `1000`, and `minpme`; the legacy access mapping also references `arrar`, whose profile row is absent. A separate read-only lookup confirms that the Appwrite Auth account `arrar` does exist and is active (`arrar@parcoto.dz`). This is therefore a missing profile-row discrepancy, not a missing Auth account; check whether any UI or legacy flow requires that profile row.

### Audit limits

- Counts are exact totals returned by TablesDB at audit time; samples were limited to two rows per table (up to 20 for the tenant registry tables).
- No full-row export, payload comparison, relation integrity scan, or row-permission count was performed.
- No production data, schema, row-security flag, or permission was modified.
- The 95 rows without a tenant field require ownership mapping via their parent vehicle/driver/provider references or a reviewed legacy company rule; do not assign them solely from `createdBy`.
