import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../../core/backend/appwrite_backend.dart';
import '../../../core/tenancy/company_context.dart';
import '../../../core/tenancy/tenant_resource_api.dart';
import '../../../providers/client_database.dart';
import '../../../domain/entities/vehicle.dart';
import 'remote_vehicle_source.dart';
import 'vehicle_row_serializer.dart';

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


  static DateTime? _legacyDate(dynamic raw) {
    if (raw == null) return null;
    final value = int.tryParse(raw.toString());
    if (value == null) return DateTime.tryParse(raw.toString());
    // New rows use Unix epoch milliseconds. Legacy rows stored an offset from
    // the application's historical reference date.
    final date = value > 1000000000000
        ? DateTime.fromMillisecondsSinceEpoch(value)
        : DateTime(2023, 11, 1, 12, 13, 15).add(Duration(milliseconds: value));
    return date;
  }

  Vehicle _fromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row.data);
    if (data['companyId']?.toString() != companyContext.companyId) {
      throw StateError('Vehicle row is outside the active company.');
    }
    final payload = data['payload'];
    if (payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final vehicle = Vehicle.fromMap(decoded);
        if (vehicle.companyId != companyContext.companyId) {
          throw StateError('Vehicle payload company does not match its row.');
        }
        return vehicle;
      }
    }
    if (payload is Map) {
      final vehicle = Vehicle.fromMap(Map<String, dynamic>.from(payload));
      if (vehicle.companyId != companyContext.companyId) {
        throw StateError('Vehicle payload company does not match its row.');
      }
      return vehicle;
    }

    // Legacy Appwrite rows store the vehicle attributes directly.
    return Vehicle.fromMap({
      'id': row.$id,
      'companyId': data['companyId'] ?? companyContext.companyId,
      'siteId': data['siteId'],
      'registration': data['matricule'],
      'foreignRegistration': data['martricule_etrang'] ?? false,
      'wilaya': data['wilaya'],
      'commune': data['commune'],
      'daira': data['daira'],
      'address': data['adresse'],
      'registrationDate': _legacyDate(data['date'])?.toIso8601String(),
      'receiptAmount': data['quittance'],
      'receiptNumber': data['numero'],
      'ownerLastName': data['nom'],
      'ownerFirstName': data['prenom'],
      'ownerProfession': data['profession'],
      'serialNumber': data['numero_serie'],
      'trim': data['trim'],
      'modelYear': data['modelYear'],
      'imageFileId': data['imageFileId'],
      'imageUrl': data['imageUrl'],
      'imageSource': data['imageSource'],
      'color': data['color'],
      'engineDisplacement': data['engineDisplacement'],
      'enginePowerHp': data['enginePowerHp'],
      'enginePowerKw': data['enginePowerKw'],
      'engineCode': data['engineCode'],
      'transmission': data['transmission'],
      'gearbox': data['gearbox'],
      'driveType': data['driveType'],
      'doors': data['doors'],
      'lengthMm': data['lengthMm'],
      'widthMm': data['widthMm'],
      'heightMm': data['heightMm'],
      'acquisitionType': data['acquisitionType'],
      'acquisitionDate': data['acquisitionDate'],
      'purchasePrice': data['purchasePrice'],
      'supplier': data['supplier'],
      'warrantyEndDate': data['warrantyEndDate'],
      'fleetNumber': data['fleetNumber'],
      'currentMileage': data['currentMileage'],
      'nextServiceMileage': data['nextServiceMileage'],
      'customFields': data['customFields'],
      'type': data['type'],
      'brand': data['marque'],
      'genre': data['genre'],
      'usefulLoad': data['charge_utile'],
      'totalWeight': data['poids_total'],
      'seats': data['place_assises'],
      'fiscalPower': data['puissance'],
      'energy': data['energie'],
      'body': data['carrosserie'],
      'usageYear': data['annee_util'],
      'previousRegistrations': data['matricule_prec'] ?? const [],
      'createdBy': data['user_creation'],
      'country': data['pays'],
      'state': data['etat'],
      'currentState': data['etatactuel'],
      'subsidiary': data['filliale'],
      'department': data['departement'],
      'direction': data['direction'],
      'ownership': data['appartenance'],
      'driverOwnership': data['appartenanceconducteur'],
      'service': data['service'] ?? false,
      'driverRegistration': data['matriculeConducteur'],
      'heavy': data['lourd'] ?? false,
      'decision': data['decision'] ?? false,
      'location': data['emplacement'],
      'perimeter': data['perimetre'] ?? 0,
      'createdAt': row.$createdAt,
      'updatedAt': row.$updatedAt,
    });
  }

  Map<String, dynamic> _toRow(Vehicle vehicle) =>
      VehicleRowSerializer.toRow(vehicle);

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
        Query.search('matricule', search.trim()),
    ];

    final result = await backend.database.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: queries,
    );
    return result.rows.map<Vehicle>(_fromRow).toList(growable: false);
  }

  @override
  Future<List<Vehicle>> getVehiclesUpdatedSince(
    DateTime since, {
    int limit = 100,
    int offset = 0,
  }) async {
    final result = await backend.database.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: [
        Query.equal('companyId', companyContext.companyId),
        Query.greaterThan(r'$updatedAt', since.toUtc().toIso8601String()),
        Query.orderAsc(r'$updatedAt'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
    return result.rows.map<Vehicle>(_fromRow).toList(growable: false);
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    try {
      final row = await backend.database.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
      );
      final rowCompanyId = row.data['companyId']?.toString();
      if (rowCompanyId == null ||
          rowCompanyId.isEmpty ||
          rowCompanyId != companyContext.companyId) {
        return null;
      }
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
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite session client is not initialized.');
    }
    await TenantResourceApi(client).createResource(
      resource: 'vehicle',
      companyId: companyContext.companyId,
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
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite session client is not initialized.');
    }
    await TenantResourceApi(client).deleteResource(
      resource: 'vehicle',
      companyId: companyContext.companyId,
      rowId: id,
    );
  }

  void _checkCompany(Vehicle vehicle) {
    if (vehicle.companyId != companyContext.companyId) {
      throw StateError('Vehicle company does not match the active company.');
    }
  }
}
