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

## Relationship audit (read-only, 2026-11-16)

A second read-only pass inspected every row in the small non-empty tables and all 70 rows in `activity`, plus the referenced vehicle rows where the relation could be resolved. Only identifiers, relation fields, ownership fields and permission principals were examined; business content was not copied here.

| Table | Relationship / ownership result | Migration implication |
|---|---|---|
| `etat` (4 rows) | All four rows reference vehicle row `39911741672`; that vehicle exists and has `companyId=essais`. | These four rows can be mapped to `essais` through a verified parent relation, subject to preserving the relation during migration. |
| `doc_vehic` (1 row) | References vehicle ID `207` and registration `62413-109-16`; a vehicle row with ID `207` was not found. | Ownership remains unresolved. Do not assign by `createdBy` alone; investigate legacy ID/registration mapping. |
| `fichereception` (1 row) | References vehicle row `45347599918`; that vehicle exists and has `companyId=essais`. | The reception row has a verified parent path to `essais`. |
| `activity` (70 rows) | Rows reference parent records through `docID`. The rows include records created by `007` and `999`; several `docID` values match known vehicle/reception/document row IDs. | Ownership must be resolved per activity through its referenced document/entity and activity type. `createdBy` is not a tenant key. |
| `planning` (10 rows) | All rows have `createdBy=007`, empty `resourceIds`, and no tenant or parent reference. User `007` has no active company membership in `company_memberships`. | Tenant ownership is unresolved. Do not migrate these rows to `essais` merely because they are in the legacy project. |
| `entreprise` (1 row) | One legacy singleton profile/settings row; no tenant key or parent reference. | Requires an explicit product decision whether this becomes the profile for `essais` or a platform-level record. |
| `options` (4), `categories` (1), `partsbrands` (1), `parts` (2) | No tenant field. Current row permissions inspected on these records refer to `user:999`. Parts reference the category and brand rows; supplier references are null. | These catalogs/inventory records need an explicit tenant scope decision and parent/reference integrity checks. Per-row user permissions are not a company boundary. |

The three vehicle rows successfully resolved during this pass (`39911741672`, `39911536667`, `45347599918`) all have `companyId=essais`. A lookup for vehicle row `207` returned not found. This does not establish whether `207` is a stale identifier, a legacy external ID, or a relation-format mismatch.

### Additional unresolved ownership cases

- `activity` records authored by `007` cannot be assigned to a company from the creator field: there is no active membership for `007`. Some activity rows authored by `999` point to records that can be resolved, but the entire set still needs a typed parent-resolution pass.
- `planning` records have no tenant field, no linked resource IDs, and no active membership for their creator. Their tenant ownership is currently unknown.
- The one `doc_vehic` record has an unresolved parent vehicle reference.
- The `entreprise` singleton and inventory/catalogue tables require a deliberate scope decision before backfill.

No records, schemas, permissions, row-security flags, memberships or Function deployments were modified by this pass.

## Platform super-admin model (clarified 2026-11-16)

The intended platform operator is the Appwrite Auth account `contact@parcoto.com`. This identity is a platform-level principal, not an ordinary company administrator and must not need a membership in every company.

Required authorization model:

- **Platform super admin**: `contact@parcoto.com`, authenticated by Appwrite. May list/access all companies, provision companies, create company administrator accounts, create ordinary user accounts, manage tenant limits, and perform platform-wide support operations.
- **Company admin**: scoped to one company by an active membership. May administer that company's operational data and members, but cannot create companies, create/promote other company admins, or grant platform privileges.
- **Company manager / employee / viewer**: scoped to one company and governed by the company's role/permission policy.
- **Ordinary user account provisioning**: controlled by the platform super admin. Company admins must not have an open-ended account-creation flow. If self-registration is ever added, it must be separately designed and gated.
- **User quota**: enforced server-side per company when the platform super admin provisions or activates users. A client-side count or disabled UI button is not an enforcement boundary.

The platform super-admin check must be based on the authenticated Appwrite account ID (or another server-controlled immutable principal mapping), never an email or role supplied in the request body. Email is useful for identifying the intended account during provisioning, but the authorization decision should bind to the stable Auth user ID. Keep the super-admin allowlist/configuration server-side; do not store a client-editable role or expose a platform-wide API key to Flutter.

The tenant API must support platform-scoped operations distinct from company-scoped operations. Company admins must continue to be checked against their active membership and requested company. The super admin's platform scope must not be simulated by creating memberships for every company.

### Current code mismatch with this model

- `create_company` currently creates a company and gives the authenticated caller an `owner` membership. This is not the desired platform provisioning flow.
- `add_member` is company-admin scoped and currently allows a company `owner` to add an `admin`. This conflicts with the requirement that only the platform super admin creates company administrators.
- There is no dedicated action to create an Appwrite Auth user and provision their company membership with a controlled role.
- There is no platform-scoped list/inspect/manage-companies API.
- There is no server-enforced per-company user quota in the current tenant Function.
- The current Flutter auth path requires an active company membership for every successful sign-in; a platform super admin with no company membership would be rejected. A separate platform session / company selection context is needed.
- The account `contact@parcoto.com` has not yet been verified against the live Appwrite Auth users in this audit. Do not assume it exists or infer its Auth user ID.

## Flutter legacy data-access audit (read-only, 2026-11-16)

The new strict tenant repositories currently cover the migrated `chauffeur` and `vehicle` data sources. Several legacy Appwrite-backed services remain on the generic `ParcOtoWebService`, whose query builder does not add an active-company filter. That generic service performs direct TablesDB list calls and therefore cannot be considered tenant-isolated.

| Feature / table | Current access path | Finding |
|---|---|---|
| Vehicles | `VehicleRepository` / `AppwriteVehicleSource` for the main vehicle table | Active-company filter and row/payload checks are present in the new path. Check all secondary vehicle operations and import/export separately. |
| Drivers | `DriverRepository` / `AppwriteDriverSource` | Active-company filter and row/payload checks are present in the new path. |
| Vehicle states (`etat`) | `VStatesDatasource` → `VehicleStateWebservice` → generic `ParcOtoWebService` | No tenant filter in the service; records are currently queried across the whole table subject only to Appwrite permissions. Must scope through the parent vehicle or add a tenant key. |
| Vehicle documents (`doc_vehic`) | Legacy generic datasource/service | No tenant filter; relation to vehicle is inconsistent/unresolved for the single live record. |
| Activity (`activity`) | `LogWebService` → generic `ParcOtoWebService` | Queries filter by date, creator and activity type, but not by company. `docID`/activity type must be resolved to the parent tenant record. |
| Planning (`planning`) | `PlanningDatasource.handleLoadMore` direct TablesDB query | No company filter or tenant field. This is a cross-company exposure risk if Appwrite permissions allow access. |
| Backups (`backup`) | `BackupWebService` and backup datasource flow | Generic query path has no company filter; backup payloads can aggregate many tenant tables, so this is a high-impact isolation boundary. |
| Workshop inventory (`parts`, `categories`, `partsbrands`, `options`) | `PartsWebService` / legacy datasource | No tenant key/filter in the legacy generic path. Need decide whether catalogs are tenant-specific or platform-shared, then enforce it consistently. |
| Company profile (`entreprise`) | `DatabaseGetter.getEntreprise()` direct row lookup at ID `1` | One project-global singleton is loaded, not a company-scoped profile. Must become company-scoped or explicitly platform-global. |
| Licensing (`trialdate`, `limits`) | `DatabaseGetter.getTrialDate()`, `getLimits()` direct row lookups | Legacy project-global semantics; cannot represent per-company subscription/user limits correctly. Must move to server-managed tenant entitlements. |
| Admin secrets (`admin_keys`) | `DatabaseGetter.setSecretKey()` direct row lookups | Client reads system encryption secrets from a table historically exposed to a global Team. Must be moved behind a server-controlled design; never exposed to ordinary company clients. |

### Cross-cutting technical findings

- `ParcOtoWebService.getQueries()` composes only feature filters, limit, offset and sort. It has no `CompanyContext` and no mandatory `companyId` predicate.
- `getSearchResult()` calls TablesDB directly. Its search branch also omits the generic paging/sort queries and has no tenant predicate.
- The base `getData()` retains a local cache on remote failure. Once tenant scoping is added, cached rows must also be keyed by company ID and cleared/rejected on company switch; otherwise a previous company's local snapshot can be rendered after a tenant change.
- `PlanningDatasource.handleLoadMore()` directly calls `DatabaseGetter.database.listRows` and does not use a tenant-aware repository.
- The offline sync engine correctly carries a `companyId` in its queue and engine lease, but that alone does not secure the remote read/write handlers. Every handler and pull path must verify that the operation company matches the active session and the remote row.
- Main vehicle/driver CRUD has stricter client-side checks, but client-side filters are not server-side security. Legacy table permissions and row security still need a server-enforced boundary.

No application code, Appwrite data, permissions, row-security flags, user accounts, memberships, Function deployment or quotas were changed by this audit.


## Platform identity and sync-boundary follow-up (read-only, 2026-11-16)

### Platform account verification

A read-only Appwrite Auth lookup for `contact@parcoto.com` returned exactly one active account:

- Auth user ID: `999`
- Name: `Service technique ParcOto`
- Email verified: yes
- Account status: active

This verifies the intended platform account exists and establishes the immutable Auth ID that should be used in a server-only super-admin allowlist. It does **not** yet make the account a platform super admin: the Function has no such allowlist check or platform-scoped actions.

The account currently also has legacy active company memberships under both duplicate GTS company IDs (as already recorded in the membership audit). Those memberships are legacy state, not the platform authorization mechanism. Do not revoke them until the dedicated platform session and company-selection flow exists and has been tested; otherwise the current login path may lock this account out.

### Additional sync and direct-access findings

The current `AppwriteSyncEngine` was inspected directly:

- The engine owns a `companyId` and asks the queue for pending operations using that company ID.
- It does not independently assert `operation.companyId == engine.companyId` before dispatching an operation to its entity handler.
- Pull handlers are zero-argument callbacks. The engine does not pass or verify a tenant context for them.
- The lease is keyed by company ID and prevents concurrent drains, but it is a coordination mechanism, not an authorization boundary.

Required hardening: validate the operation tenant against the engine/session tenant before dispatch; require every write handler and pull handler to obtain the active tenant context and apply tenant predicates/ownership checks. The Appwrite API must enforce authorization server-side as well; a local queue check is only defense in depth.

The current `DatabaseGetter` also exposes generic direct CRUD helpers:

- `addDocument`, `updateDocument`, and `getDocument` address arbitrary table/row IDs without a tenant predicate or ownership check.
- `listDocuments` paginates an entire table without a tenant predicate.
- `getUser` gives user ID `999` a hard-coded year-2100 trial expiry, and loads a profile from the global `users` table. This is legacy licensing behavior, not an acceptable platform-super-admin authorization check.
- `getLimits` and `getEntreprise` load singleton rows `1`; they remain project-global and cannot represent per-company entitlements or profiles.
- `setSecretKey` still reads encryption key material directly from `admin_keys` in the Flutter client.

Planning remains a direct unscoped TablesDB query against `planning`. The tenant owner of the ten existing planning rows is unresolved, so simply adding `companyId=essais` would be an unverified data migration.

### Current status

No application code was changed in this follow-up. No Appwrite users, memberships, records, schemas, permissions, Function configuration or deployments were modified. Company onboarding remains disabled. The platform Auth ID is now verified, but tenant isolation is still incomplete and production onboarding must remain blocked.
