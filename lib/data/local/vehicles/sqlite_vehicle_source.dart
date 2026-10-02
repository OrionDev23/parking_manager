import 'package:sqlite3/sqlite3.dart';
import '../../../core/database/local_database.dart';
import '../../../domain/entities/vehicle.dart';
import 'local_vehicle_source.dart';

class SqliteVehicleSource implements LocalVehicleSource {
  final LocalDatabase localDatabase;
  SqliteVehicleSource(this.localDatabase);
  Database get _db => localDatabase.database;

  Vehicle _fromRow(Row row) => Vehicle(
    id: row['id'] as String, companyId: row['company_id'] as String,
    siteId: row['site_id'] as String?, registration: row['registration'] as String,
    brand: row['brand'] as String?, model: row['model'] as String?, color: row['color'] as String?,
    status: VehicleStatus.values.firstWhere((e) => e.name == row['status'], orElse: () => VehicleStatus.active),
    createdAt: DateTime.parse(row['created_at'] as String), updatedAt: DateTime.parse(row['updated_at'] as String));

  @override
  Future<List<Vehicle>> getVehicles({String? search, int? limit, int offset = 0}) async {
    final query = StringBuffer('SELECT * FROM vehicles');
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      query.write(' WHERE registration LIKE ? OR brand LIKE ? OR model LIKE ?');
      final value = '%${search.trim()}%';
      args.addAll([value, value, value]);
    }
    query.write(' ORDER BY updated_at DESC');
    if (limit != null) { query.write(' LIMIT ? OFFSET ?'); args.addAll([limit, offset]); }
    return _db.select(query.toString(), args).map(_fromRow).toList(growable: false);
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    final rows = _db.select('SELECT * FROM vehicles WHERE id = ? LIMIT 1', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsertVehicle(Vehicle vehicle) async {
    _db.execute('''INSERT INTO vehicles
      (id, company_id, site_id, registration, brand, model, color, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET company_id=excluded.company_id, site_id=excluded.site_id,
      registration=excluded.registration, brand=excluded.brand, model=excluded.model,
      color=excluded.color, status=excluded.status, updated_at=excluded.updated_at''', [
      vehicle.id, vehicle.companyId, vehicle.siteId, vehicle.registration, vehicle.brand,
      vehicle.model, vehicle.color, vehicle.status.name, vehicle.createdAt.toIso8601String(), vehicle.updatedAt.toIso8601String()]);
  }

  @override
  Future<void> deleteVehicle(String id) async { _db.execute('DELETE FROM vehicles WHERE id = ?', [id]); }
}
