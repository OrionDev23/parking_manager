# Read-only tenant migration audit

Run this before creating or backfilling tenant columns:

```bash
APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1 \
APPWRITE_PROJECT_ID=essais \
APPWRITE_DATABASE_ID=6531ad112080ae3b14a7 \
APPWRITE_API_KEY=<server-side-key-with-tablesdb.read> \
LEGACY_COMPANY_ID=essais \
node scripts/tenant-migration-audit.mjs
```

The script is strictly read-only. It enumerates operational tables and reports:

- row count per table;
- records with no `companyId`;
- records currently assigned to the legacy company ID;
- any other company IDs found;
- rows with and without row-level permissions.

It does not print record contents, change schemas, update rows, or alter permissions. Store the API key only in a secure environment variable; never commit it.

Review the report before preparing a backfill. A table that currently lacks a `companyId` column will be counted as having missing tenant ownership for every row. Confirm the ownership mapping before applying any migration.
