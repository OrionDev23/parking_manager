import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  factory LocalDatabase() => instance;

  LocalDatabase._();
  Database get database =>
      _database ??
      (throw StateError('LocalDatabase has not been initialized.'));

  Future<void> open() async {
    if (_database != null) return;
    final directory = await getApplicationSupportDirectory();
    await Directory(directory.path).create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}parcoto.db');
    final opened = sqlite3.open(file.path);
    _database = opened;
    _migrate(opened);
  }

  void _migrate(Database db) {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA journal_mode = WAL');
    db.execute(
      'CREATE TABLE IF NOT EXISTS schema_migrations '
      '(version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)',
    );
    final version =
        db
                .select(
                  'SELECT COALESCE(MAX(version), 0) AS version FROM schema_migrations',
                )
                .first['version']
            as int;

    if (version < 1) {
      db.execute(
        '''CREATE TABLE vehicles (
        id TEXT PRIMARY KEY, company_id TEXT NOT NULL, site_id TEXT,
        registration TEXT NOT NULL, brand TEXT, model TEXT, color TEXT,
        status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
      );
      db.execute('CREATE INDEX idx_vehicles_company ON vehicles(company_id)');
      db.execute(
        'CREATE INDEX idx_vehicles_registration ON vehicles(registration)',
      );
      db.execute('CREATE INDEX idx_vehicles_site ON vehicles(site_id)');
      db.execute('''CREATE TABLE sync_operations (
        id TEXT PRIMARY KEY, company_id TEXT NOT NULL, device_id TEXT NOT NULL,
        entity TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL,
        payload TEXT NOT NULL, created_at TEXT NOT NULL, status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0)''');
      db.execute(
        'CREATE INDEX idx_sync_operations_status ON sync_operations(status, created_at)',
      );
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (1, datetime('now'))",
      );
    }
    if (version < 2) {
      db.execute('ALTER TABLE vehicles ADD COLUMN payload TEXT');
      db.execute("UPDATE vehicles SET payload = '{}' WHERE payload IS NULL");
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (2, datetime('now'))",
      );
    }

    // The driver repository uses this table for every local-first read.
    // Keep this migration idempotent so existing installations are repaired.
    if (version < 3) {
      db.execute('''CREATE TABLE IF NOT EXISTS drivers (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        site_id TEXT,
        first_name TEXT NOT NULL DEFAULT '',
        last_name TEXT NOT NULL DEFAULT '',
        registration TEXT NOT NULL DEFAULT '',
        email TEXT,
        phone TEXT,
        state INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        payload TEXT NOT NULL DEFAULT '{}'
      )''');
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_drivers_company ON drivers(company_id)',
      );
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_drivers_registration ON drivers(registration)',
      );
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (3, datetime('now'))",
      );
    }

    if (version < 4) {
      db.execute('''CREATE TABLE IF NOT EXISTS legacy_module_cache (
        company_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        PRIMARY KEY (company_id, entity, entity_id)
      )''');
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_legacy_module_cache_entity ON legacy_module_cache(company_id, entity)',
      );
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (4, datetime('now'))",
      );
    }

    if (version < 5) {
      db.execute('''CREATE TABLE IF NOT EXISTS sync_engine_leases (
        company_id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        lease_until TEXT NOT NULL
      )''');
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (5, datetime('now'))",
      );
    }

    if (version < 6) {
      db.execute('ALTER TABLE sync_operations ADD COLUMN conflict_reason TEXT');
      db.execute('ALTER TABLE sync_operations ADD COLUMN conflicted_at TEXT');
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_operations_conflicts ON sync_operations(company_id, status, conflicted_at)',
      );
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (6, datetime('now'))",
      );
    }

    if (version < 7) {
      db.execute('''CREATE TABLE IF NOT EXISTS sync_conflict_resolutions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL,
        company_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        resolution TEXT NOT NULL,
        resolved_at TEXT NOT NULL
      )''');
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_conflict_resolutions_company ON sync_conflict_resolutions(company_id, resolved_at)',
      );
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (7, datetime('now'))",
      );
    }

    if (version < 8) {
      db.execute('''CREATE TABLE IF NOT EXISTS sync_cursors (
        company_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        cursor TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (company_id, entity)
      )''');
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (8, datetime('now'))",
      );
    }

    if (version < 9) {
      db.execute('''CREATE TABLE IF NOT EXISTS sync_reconciliation (
        company_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        reconciled_at TEXT NOT NULL,
        PRIMARY KEY (company_id, entity)
      )''');
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (9, datetime('now'))",
      );
    }

    if (version < 10) {
      db.execute('''CREATE TABLE IF NOT EXISTS sync_remote_snapshot (
        company_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        PRIMARY KEY (company_id, entity, entity_id)
      )''');
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (10, datetime('now'))",
      );
    }

    if (version < 11) {
      db.execute('''CREATE TABLE IF NOT EXISTS startup_migrations (
        company_id TEXT NOT NULL,
        migration_key TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        PRIMARY KEY (company_id, migration_key)
      )''');
      db.execute(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (11, datetime('now'))",
      );
    }
  }

  bool isStartupMigrationComplete({
    required String companyId,
    required String migrationKey,
  }) {
    final rows = database.select(
      'SELECT 1 FROM startup_migrations WHERE company_id = ? AND migration_key = ? LIMIT 1',
      [companyId, migrationKey],
    );
    return rows.isNotEmpty;
  }

  void markStartupMigrationComplete({
    required String companyId,
    required String migrationKey,
  }) {
    database.execute(
      '''INSERT INTO startup_migrations(company_id, migration_key, completed_at)
         VALUES (?, ?, ?)
         ON CONFLICT(company_id, migration_key) DO UPDATE SET
           completed_at=excluded.completed_at''',
      [
        companyId,
        migrationKey,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Set<String> readRemoteSnapshotIds({
    required String companyId,
    required String entity,
  }) {
    final rows = database.select(
      'SELECT entity_id FROM sync_remote_snapshot WHERE company_id=? AND entity=?',
      [companyId, entity],
    );
    return rows.map((row) => row['entity_id'] as String).toSet();
  }

  void replaceRemoteSnapshot({
    required String companyId,
    required String entity,
    required Set<String> entityIds,
  }) {
    database.execute('BEGIN IMMEDIATE');
    try {
      database.execute(
        'DELETE FROM sync_remote_snapshot WHERE company_id=? AND entity=?',
        [companyId, entity],
      );
      for (final id in entityIds) {
        database.execute(
          'INSERT INTO sync_remote_snapshot(company_id, entity, entity_id) VALUES (?, ?, ?)',
          [companyId, entity, id],
        );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  DateTime? readReconciliationTime({
    required String companyId,
    required String entity,
  }) {
    final rows = database.select(
      'SELECT reconciled_at FROM sync_reconciliation WHERE company_id=? AND entity=?',
      [companyId, entity],
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['reconciled_at'] as String);
  }

  void saveReconciliationTime({
    required String companyId,
    required String entity,
    required DateTime reconciledAt,
  }) {
    database.execute(
      '''INSERT INTO sync_reconciliation(company_id, entity, reconciled_at)
         VALUES (?, ?, ?)
         ON CONFLICT(company_id, entity) DO UPDATE SET
           reconciled_at=excluded.reconciled_at''',
      [companyId, entity, reconciledAt.toUtc().toIso8601String()],
    );
  }

  DateTime? readSyncCursor({
    required String companyId,
    required String entity,
  }) {
    final rows = database.select(
      'SELECT cursor FROM sync_cursors WHERE company_id=? AND entity=?',
      [companyId, entity],
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['cursor'] as String);
  }

  void saveSyncCursor({
    required String companyId,
    required String entity,
    required DateTime cursor,
  }) {
    database.execute(
      '''INSERT INTO sync_cursors(company_id, entity, cursor, updated_at)
         VALUES (?, ?, ?, ?)
         ON CONFLICT(company_id, entity) DO UPDATE SET
           cursor=excluded.cursor, updated_at=excluded.updated_at''',
      [
        companyId,
        entity,
        cursor.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  List<Map<String, dynamic>> readLegacyCache({
    required String companyId,
    required String entity,
  }) {
    final rows = database.select(
      'SELECT payload FROM legacy_module_cache WHERE company_id = ? AND entity = ?',
      [companyId, entity],
    );
    return rows
        .map(
          (row) => jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        )
        .toList(growable: false);
  }

  void cacheLegacyRow({
    required String companyId,
    required String entity,
    required String entityId,
    required Map<String, dynamic> payload,
    bool overwrite = true,
  }) {
    final conflictAction = overwrite ? 'REPLACE' : 'IGNORE';
    database.execute(
      '''INSERT OR $conflictAction INTO legacy_module_cache
        (company_id, entity, entity_id, payload, cached_at)
        VALUES (?, ?, ?, ?, ?)''',
      [
        companyId,
        entity,
        entityId,
        jsonEncode(payload),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  void deleteLegacyRow({
    required String companyId,
    required String entity,
    required String entityId,
  }) {
    database.execute(
      'DELETE FROM legacy_module_cache WHERE company_id = ? AND entity = ? AND entity_id = ?',
      [companyId, entity, entityId],
    );
  }

  Future<void> close() async {
    _database?.close();
    _database = null;
  }
}
