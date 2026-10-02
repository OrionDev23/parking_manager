import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../../core/backend/appwrite_backend.dart';
import '../../../core/tenancy/company_context.dart';
import '../../../domain/entities/vehicle.dart';
import 'remote_vehicle_source.dart';

class AppwriteVehicleSource implements RemoteVehicleSource {
  final AppwriteBackend backend;
  final CompanyContext companyContext;
  final String databaseId;
  final String tableId;

  AppwriteVehicleSource({
    required this.backend,
    required this.companyContext,
    required this.databaseId,
    required this.tableId,
  });

  Vehicle _fromRow(Row row) {
    final data = Map<String, dynamic>.from(row.data);
    final payload = data['payload'];
    if (payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return Vehicle.fromMap(decoded);
      }
    }
    if (payload is Map) {
      return Vehicle.fromMap(Map<String, dynamic>.from(payload));
    }
    throw const FormatException('Vehicle remote payload is missing.');
  }

  Map<String, dynamic> _toRow(Vehicle vehicle) => {
        'companyId': vehicle.companyId,
        'siteId': vehicle.siteId,
        'registration': vehicle.registration,
        'brand': vehicle.brand,
        'model': vehicle.type,
        'payload': jsonEncode(vehicle.toMap()),
      };

  @override
  Future<List<Vehicle>> getVehicles({
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final queries = <String>[
      Query.equal('companyId', companyContext.companyId),
      Query.orderDesc(r'$updatedAt'),
      Query.limit(limit ?? 100),
      Query.offset(offset),
      if (search != null && search.trim().isNotEmpty)
        Query.search('registration', search.trim()),
    ];

    final result = await backend.database.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: queries,
    );
    return result.rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    try {
      final row = await backend.database.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
      );
      final vehicle = _fromRow(row);
      if (vehicle.companyId != companyContext.companyId) return null;
      return vehicle;
    } on AppwriteException catch (error) {
      if (error.code == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    _checkCompany(vehicle);
    await backend.database.createRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: vehicle.id,
      data: _toRow(vehicle),
    );
    return vehicle;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    _checkCompany(vehicle);
    await backend.database.updateRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: vehicle.id,
      data: _toRow(vehicle),
    );
    return vehicle;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    final vehicle = await getVehicle(id);
    if (vehicle == null) return;
    _checkCompany(vehicle);
    await backend.database.deleteRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: id,
    );
  }

  void _checkCompany(Vehicle vehicle) {
    if (vehicle.companyId != companyContext.companyId) {
      throw StateError('Vehicle company does not match the active company.');
    }
  }
}
