import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/local_database.dart';
import '../../../domain/entities/vehicle.dart';
import 'local_vehicle_source.dart';

class SqliteVehicleSource implements LocalVehicleSource {
  final LocalDatabase localDatabase;
  final String companyId;

  SqliteVehicleSource(this.localDatabase, {required this.companyId});

  Database get _db => localDatabase.database;

  Vehicle _fromRow(Row row) {
    final decoded = jsonDecode(row['payload'] as String? ?? '{}');
    if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
      return Vehicle.fromMap(decoded);
    }
    return Vehicle(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      siteId: row['site_id'] as String?,
      registration: row['registration'] as String,
      foreignRegistration: false,
      brand: row['brand'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Future<List<Vehicle>> getVehicles({
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final query = StringBuffer(
      'SELECT * FROM vehicles WHERE company_id = ?',
    );
    final args = <Object?>[companyId];

    if (search != null && search.trim().isNotEmpty) {
      query.write(
        ' AND (registration LIKE ? OR brand LIKE ? OR model LIKE ? OR payload LIKE ?)',
      );
      final value = '%${search.trim()}%';
      args.addAll([value, value, value, value]);
    }

    query.write(' ORDER BY updated_at DESC');
    if (limit != null) {
      query.write(' LIMIT ? OFFSET ?');
      args.addAll([limit, offset]);
    } else if (offset > 0) {
      query.write(' LIMIT -1 OFFSET ?');
      args.add(offset);
    }

    return _db
        .select(query.toString(), args)
        .map(_fromRow)
        .toList(growable: false);
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    final rows = _db.select(
      'SELECT * FROM vehicles WHERE id = ? AND company_id = ? LIMIT 1',
      [id, companyId],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsertVehicle(Vehicle vehicle) async {
    if (vehicle.companyId != companyId) {
      throw StateError('Vehicle company does not match the local company.');
    }
    final payload = jsonEncode(vehicle.toMap());
    _db.execute(
      '''INSERT INTO vehicles
      (id, company_id, site_id, registration, brand, model, color, status, created_at, updated_at, payload)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        company_id=excluded.company_id,
        site_id=excluded.site_id,
        registration=excluded.registration,
        brand=excluded.brand,
        model=excluded.model,
        color=excluded.color,
        status=excluded.status,
        updated_at=excluded.updated_at,
        payload=excluded.payload''',
      [
        vehicle.id,
        vehicle.companyId,
        vehicle.siteId,
        vehicle.registration,
        vehicle.brand,
        vehicle.type,
        null,
        'active',
        vehicle.createdAt.toIso8601String(),
        vehicle.updatedAt.toIso8601String(),
        payload,
      ],
    );
  }

  @override
  Future<void> deleteVehicle(String id) async {
    _db.execute(
      'DELETE FROM vehicles WHERE id = ? AND company_id = ?',
      [id, companyId],
    );
  }
}
