import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../../../core/database/local_database.dart';
import '../../../domain/entities/driver.dart';
import 'local_driver_source.dart';

class SqliteDriverSource implements LocalDriverSource {
  final LocalDatabase localDatabase;
  final String companyId;
  SqliteDriverSource(this.localDatabase, {required this.companyId});
  Database get _db => localDatabase.database;

  Driver _fromRow(Row row) {
    final decoded = jsonDecode(row['payload'] as String? ?? '{}');
    if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
      return Driver.fromMap(decoded);
    }
    return Driver(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      siteId: row['site_id'] as String?,
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      registration: row['registration'] as String? ?? '',
      state: (row['state'] as int?) ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Future<List<Driver>> getDrivers({
    String? search, int? limit, int offset = 0, bool includeArchived = false,
  }) async {
    final query = StringBuffer('SELECT * FROM drivers WHERE company_id = ?');
    final args = <Object?>[companyId];
    if (!includeArchived) query.write(' AND state != 3');
    if (search != null && search.trim().isNotEmpty) {
      query.write(' AND (first_name LIKE ? OR last_name LIKE ? OR registration LIKE ? OR email LIKE ? OR phone LIKE ?)');
      final value = '%${'${search.trim()}'}%';
      args.addAll([value, value, value, value, value]);
    }
    query.write(' ORDER BY updated_at DESC');
    if (limit != null) {
      query.write(' LIMIT ? OFFSET ?');
      args.addAll([limit, offset]);
    }
    return _db.select(query.toString(), args).map(_fromRow).toList(growable: false);
  }

  @override
  Future<Driver?> getDriver(String id) async {
    final rows = _db.select(
      'SELECT * FROM drivers WHERE id = ? AND company_id = ? LIMIT 1',
      [id, companyId],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsertDriver(Driver driver) async {
    final payload = jsonEncode(driver.toMap());
    _db.execute(
      '''INSERT INTO drivers
      (id, company_id, site_id, first_name, last_name, registration, email, phone, state, created_at, updated_at, payload)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        company_id=excluded.company_id, site_id=excluded.site_id,
        first_name=excluded.first_name, last_name=excluded.last_name,
        registration=excluded.registration, email=excluded.email,
        phone=excluded.phone, state=excluded.state,
        updated_at=excluded.updated_at, payload=excluded.payload''',
      [
        driver.id, driver.companyId, driver.siteId, driver.firstName, driver.lastName,
        driver.registration, driver.email, driver.phone, driver.state,
        driver.createdAt.toIso8601String(), driver.updatedAt.toIso8601String(), payload,
      ],
    );
  }

  @override
  Future<void> deleteDriver(String id) async {
    _db.execute('DELETE FROM drivers WHERE id = ? AND company_id = ?',
        [id, companyId]);
  }
}
