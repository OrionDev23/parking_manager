import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  factory LocalDatabase() => instance;

  LocalDatabase._();
  Database get database => _database ?? (throw StateError('LocalDatabase has not been initialized.'));

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
    db.execute('CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)');
    final version = db.select('SELECT COALESCE(MAX(version), 0) AS version FROM schema_migrations').first['version'] as int;

    if (version < 1) {
      db.execute('''CREATE TABLE vehicles (
        id TEXT PRIMARY KEY, company_id TEXT NOT NULL, site_id TEXT,
        registration TEXT NOT NULL, brand TEXT, model TEXT, color TEXT,
        status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
      db.execute('CREATE INDEX idx_vehicles_company ON vehicles(company_id)');
      db.execute('CREATE INDEX idx_vehicles_registration ON vehicles(registration)');
      db.execute('CREATE INDEX idx_vehicles_site ON vehicles(site_id)');
      db.execute('''CREATE TABLE sync_operations (
        id TEXT PRIMARY KEY, company_id TEXT NOT NULL, device_id TEXT NOT NULL,
        entity TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL,
        payload TEXT NOT NULL, created_at TEXT NOT NULL, status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0)''');
      db.execute('CREATE INDEX idx_sync_operations_status ON sync_operations(status, created_at)');
      db.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (1, datetime('now'))");
    }
    if (version < 2) {
      db.execute('ALTER TABLE vehicles ADD COLUMN payload TEXT');
      db.execute("UPDATE vehicles SET payload = '{}' WHERE payload IS NULL");
      db.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (2, datetime('now'))");
    }
  }

  Future<void> close() async {
    _database?.close();
    _database = null;
  }
}
