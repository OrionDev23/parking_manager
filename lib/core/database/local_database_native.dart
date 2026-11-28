import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  factory LocalDatabase() => instance;

  LocalDatabase._();

  @visibleForTesting
  LocalDatabase.inMemoryForTesting() {
    final opened = sqlite3.openInMemory();
    try {
      _migrate(opened);
      _database = opened;
    } catch (_) {
      opened.close();
      rethrow;
    }
  }
  Database get database =>
      _database ??
      (throw StateError('LocalDatabase has not been initialized.'));

  Future<void> open() async {
    if (_database != null) return;
    final directory = await getApplicationSupportDirectory();
    await Directory(directory.path).create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}parcoto.db');
    final opened = sqlite3.open(file.path);
    try {
      _migrate(opened);
      _database = opened;
    } catch (_) {
      opened.close();
      rethrow;
    }
  }

  @visibleForTesting
  static void migrateForTesting(Database database) {
    LocalDatabase._()._migrate(database);
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

    if (version < 12) {
      db.execute('BEGIN IMMEDIATE');
      try {
        bool hasColumn(String table, String column) {
          return db
              .select('PRAGMA table_info($table)')
              .any((row) => row['name'] == column);
        }

        void addColumnIfMissing(String table, String column, String definition) {
          if (!hasColumn(table, column)) {
            db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
          }
        }

        // Additive and restart-safe: if the process is interrupted midway,
        // rerunning this migration checks each column before adding it.
        addColumnIfMissing(
          'sync_operations',
          'payload_version',
          'INTEGER NOT NULL DEFAULT 1',
        );
        addColumnIfMissing(
          'sync_operations',
          'idempotency_key',
          "TEXT NOT NULL DEFAULT ''",
        );
        addColumnIfMissing('sync_operations', 'next_attempt_at', 'TEXT');
        addColumnIfMissing('sync_operations', 'last_error_code', 'TEXT');
        addColumnIfMissing('sync_operations', 'last_error_message', 'TEXT');
        addColumnIfMissing('sync_operations', 'completed_at', 'TEXT');

        // Existing operations keep their original IDs; those IDs become
        // their stable idempotency keys so queued work remains replayable.
        db.execute(
          "UPDATE sync_operations SET idempotency_key = id "
          "WHERE idempotency_key IS NULL OR idempotency_key = ''",
        );
        db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS '
          'ux_sync_operations_idempotency '
          'ON sync_operations(company_id, idempotency_key)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sync_operations_due '
          'ON sync_operations(company_id, status, next_attempt_at, created_at)',
        );
        db.execute(
          "INSERT INTO schema_migrations(version, applied_at) "
          "VALUES (12, datetime('now'))",
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }
  }


    if (version < 13) {
      db.execute('BEGIN IMMEDIATE');
      try {
        bool hasColumn(String table, String column) => db
            .select('PRAGMA table_info($table)')
            .any((row) => row['name'] == column);

        void addColumnIfMissing(String table, String column, String definition) {
          if (!hasColumn(table, column)) {
            db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
          }
        }

        addColumnIfMissing('sync_operations', 'base_revision', 'INTEGER');
        addColumnIfMissing(
          'sync_operations',
          'depends_on_operation_id',
          'TEXT',
        );
        addColumnIfMissing(
          'sync_operations',
          'sequence_no',
          'INTEGER NOT NULL DEFAULT 0',
        );

        // Preserve the original order deterministically per tenant. rowid is
        // only a tie-breaker for legacy rows with identical timestamps.
        final oldOperations = db.select(
          'SELECT id, company_id FROM sync_operations '
          'ORDER BY company_id, created_at, rowid',
        );
        String? currentCompany;
        var sequence = 0;
        for (final row in oldOperations) {
          final operationCompany = row['company_id'] as String;
          if (operationCompany != currentCompany) {
            currentCompany = operationCompany;
            sequence = 0;
          }
          sequence++;
          db.execute(
            'UPDATE sync_operations SET sequence_no = ? WHERE id = ?',
            [sequence, row['id']],
          );
        }

        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sync_entity_order '
          'ON sync_operations(company_id, entity, entity_id, sequence_no)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sync_operation_dependency '
          'ON sync_operations(company_id, depends_on_operation_id)',
        );
        db.execute(
          "INSERT INTO schema_migrations(version, applied_at) "
          "VALUES (13, datetime('now'))",
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }

    if (version < 14) {
      db.execute('BEGIN IMMEDIATE');
      try {
        bool hasColumn(String table, String column) => db
            .select('PRAGMA table_info($table)')
            .any((row) => row['name'] == column);

        void addColumnIfMissing(String table, String column, String definition) {
          if (!hasColumn(table, column)) {
            db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
          }
        }

        addColumnIfMissing(
          'vehicles',
          'server_revision',
          'INTEGER NOT NULL DEFAULT 0',
        );
        addColumnIfMissing(
          'drivers',
          'server_revision',
          'INTEGER NOT NULL DEFAULT 0',
        );
        db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS ux_vehicles_company_id '
          'ON vehicles(company_id, id)',
        );
        db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS ux_drivers_company_id '
          'ON drivers(company_id, id)',
        );

        db.execute('''
          CREATE TABLE IF NOT EXISTS sites (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            UNIQUE(company_id, code)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS vehicle_assignments (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            vehicle_id TEXT NOT NULL,
            driver_id TEXT,
            status TEXT NOT NULL,
            start_at TEXT NOT NULL,
            end_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            FOREIGN KEY(company_id, vehicle_id)
              REFERENCES vehicles(company_id, id),
            FOREIGN KEY(company_id, driver_id)
              REFERENCES drivers(company_id, id)
          )
        ''');
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sites_company_status '
          'ON sites(company_id, status)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_vehicle_assignments_vehicle '
          'ON vehicle_assignments(company_id, vehicle_id, status, start_at)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_vehicle_assignments_driver '
          'ON vehicle_assignments(company_id, driver_id, status, start_at)',
        );
        db.execute(
          "INSERT INTO schema_migrations(version, applied_at) "
          "VALUES (14, datetime('now'))",
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }

    if (version < 15) {
      db.execute('BEGIN IMMEDIATE');
      try {
        db.execute('''
          CREATE TABLE IF NOT EXISTS parking_lots (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            site_id TEXT NOT NULL,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            address TEXT,
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            UNIQUE(company_id, site_id, code),
            FOREIGN KEY(company_id, site_id)
              REFERENCES sites(company_id, id)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS parking_layouts (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            parking_lot_id TEXT NOT NULL,
            name TEXT NOT NULL,
            version INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'draft',
            width_m REAL NOT NULL,
            height_m REAL NOT NULL,
            unit TEXT NOT NULL DEFAULT 'm',
            grid_step_m REAL NOT NULL DEFAULT 0.25,
            background_file_id TEXT,
            background_transform_json TEXT,
            layers_json TEXT NOT NULL DEFAULT '[]',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            UNIQUE(company_id, parking_lot_id, version),
            FOREIGN KEY(company_id, parking_lot_id)
              REFERENCES parking_lots(company_id, id)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS parking_zones (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            parking_lot_id TEXT NOT NULL,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            zone_type TEXT NOT NULL DEFAULT 'standard',
            status TEXT NOT NULL DEFAULT 'active',
            geometry_json TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0,
            color_token TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            UNIQUE(company_id, parking_lot_id, code),
            FOREIGN KEY(company_id, parking_lot_id)
              REFERENCES parking_lots(company_id, id)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS parking_spaces (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            parking_zone_id TEXT NOT NULL,
            code TEXT NOT NULL,
            space_type TEXT NOT NULL DEFAULT 'standard',
            status TEXT NOT NULL DEFAULT 'active',
            x_m REAL,
            y_m REAL,
            width_m REAL,
            length_m REAL,
            rotation_deg REAL NOT NULL DEFAULT 0,
            shape_type TEXT NOT NULL DEFAULT 'rectangle',
            geometry_json TEXT,
            row_code TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0,
            max_length_mm INTEGER,
            max_width_mm INTEGER,
            max_height_mm INTEGER,
            max_weight_kg INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            UNIQUE(company_id, parking_zone_id, code),
            FOREIGN KEY(company_id, parking_zone_id)
              REFERENCES parking_zones(company_id, id)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS parking_access_events (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            parking_lot_id TEXT NOT NULL,
            vehicle_id TEXT,
            event_type TEXT NOT NULL,
            source_type TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            recorded_at TEXT NOT NULL,
            registration_captured TEXT,
            registration_normalized TEXT,
            confidence REAL,
            device_id TEXT,
            actor_user_id TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            FOREIGN KEY(company_id, parking_lot_id)
              REFERENCES parking_lots(company_id, id),
            FOREIGN KEY(company_id, vehicle_id)
              REFERENCES vehicles(company_id, id)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS vehicle_parking_assignments (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            vehicle_id TEXT NOT NULL,
            parking_space_id TEXT NOT NULL,
            assignment_type TEXT NOT NULL DEFAULT 'assigned',
            status TEXT NOT NULL DEFAULT 'active',
            source_type TEXT NOT NULL DEFAULT 'manual',
            start_at TEXT NOT NULL,
            end_at TEXT,
            entry_event_id TEXT,
            exit_event_id TEXT,
            assigned_by TEXT,
            ended_by TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            FOREIGN KEY(company_id, vehicle_id)
              REFERENCES vehicles(company_id, id),
            FOREIGN KEY(company_id, parking_space_id)
              REFERENCES parking_spaces(company_id, id)
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS parking_media (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            parking_lot_id TEXT NOT NULL,
            layout_id TEXT,
            file_id TEXT NOT NULL,
            purpose TEXT NOT NULL,
            file_name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            sha256 TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            payload TEXT NOT NULL DEFAULT '{}',
            UNIQUE(company_id, id),
            UNIQUE(company_id, file_id),
            FOREIGN KEY(company_id, parking_lot_id)
              REFERENCES parking_lots(company_id, id),
            FOREIGN KEY(company_id, layout_id)
              REFERENCES parking_layouts(company_id, id)
          )
        ''');

        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_lots_site_status '
          'ON parking_lots(company_id, site_id, status)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_layouts_lot_status '
          'ON parking_layouts(company_id, parking_lot_id, status)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_zones_lot_order '
          'ON parking_zones(company_id, parking_lot_id, sort_order)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_spaces_zone_status '
          'ON parking_spaces(company_id, parking_zone_id, status)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_spaces_code '
          'ON parking_spaces(company_id, code)',
        );
        db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS ux_parking_active_space '
          'ON vehicle_parking_assignments(company_id, parking_space_id) '
          "WHERE status = 'active'",
        );
        db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS ux_parking_active_vehicle '
          'ON vehicle_parking_assignments(company_id, vehicle_id) '
          "WHERE status = 'active'",
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_vehicle_parking_history '
          'ON vehicle_parking_assignments(company_id, vehicle_id, start_at)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_events_lot_time '
          'ON parking_access_events(company_id, parking_lot_id, occurred_at)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_events_vehicle_time '
          'ON parking_access_events(company_id, vehicle_id, occurred_at)',
        );
        db.execute(
          'CREATE INDEX IF NOT EXISTS idx_parking_media_lot '
          'ON parking_media(company_id, parking_lot_id, purpose)',
        );
        db.execute(
          "INSERT INTO schema_migrations(version, applied_at) "
          "VALUES (15, datetime('now'))",
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }


    if (version < 16) {
      db.execute('BEGIN IMMEDIATE');
      try {
        // Physical assignments occupy the space now. Reservations are
        // time-window commitments and are checked by ParkingAssignmentPolicy.
        db.execute('DROP INDEX IF EXISTS ux_parking_active_space');
        db.execute('DROP INDEX IF EXISTS ux_parking_active_vehicle');
        db.execute(
          'CREATE UNIQUE INDEX ux_parking_active_space '
          'ON vehicle_parking_assignments(company_id, parking_space_id) '
          "WHERE status = 'active' AND assignment_type <> 'reserved'",
        );
        db.execute(
          'CREATE UNIQUE INDEX ux_parking_active_vehicle '
          'ON vehicle_parking_assignments(company_id, vehicle_id) '
          "WHERE status = 'active' AND assignment_type <> 'reserved'",
        );
        db.execute(
          "INSERT INTO schema_migrations(version, applied_at) "
          "VALUES (16, datetime('now'))",
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
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
