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

  static DateTime? _legacyDate(dynamic raw) {
    if (raw == null) return null;
    final value = int.tryParse(raw.toString());
    if (value == null) return DateTime.tryParse(raw.toString());
    // New rows use Unix epoch milliseconds. Legacy rows stored an offset from
    // the application's historical reference date.
    final date = value > 1000000000000
        ? DateTime.fromMillisecondsSinceEpoch(value)
        : DateTime(2023, 11, 1, 12, 13, 15)
            .add(Duration(milliseconds: value));
    return date;
  }

  Vehicle _fromRow(dynamic row) {
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
      'type': data['type'],
      'brand': data['marque'],
      'genre': data['genre'],
      'usefulLoad': data['charge_utile'],
      'totalWeight': data['poids_total'],
      'seats': data['place_assises'],
      'power': data['puissance'],
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

  Map<String, dynamic> _toRow(Vehicle vehicle) => {
        'companyId': vehicle.companyId,
        'siteId': vehicle.siteId,
        // Keep the exact legacy Appwrite attribute names defined in
        // lib/serializables/vehicle/vehicle.dart.
        'matricule': vehicle.registration,
        'martricule_etrang': vehicle.foreignRegistration,
        'wilaya': vehicle.wilaya,
        'commune': vehicle.commune,
        'daira': vehicle.daira,
        'adresse': vehicle.address,
        'date': vehicle.registrationDate?.millisecondsSinceEpoch,
        'quittance': vehicle.receiptAmount,
        'numero': vehicle.receiptNumber,
        'nom': vehicle.ownerLastName,
        'prenom': vehicle.ownerFirstName,
        'profession': vehicle.ownerProfession,
        'numero_serie': vehicle.serialNumber,
        'type': vehicle.type,
        'marque': vehicle.brand,
        'genre': vehicle.genre,
        'charge_utile': vehicle.usefulLoad,
        'poids_total': vehicle.totalWeight,
        'place_assises': vehicle.seats,
        'puissance': vehicle.power,
        'energie': vehicle.energy,
        'carrosserie': vehicle.body,
        'annee_util': vehicle.usageYear,
        'matricule_prec': vehicle.previousRegistrations,
        'user_creation': vehicle.createdBy,
        'pays': vehicle.country,
        'etat': vehicle.state,
        'etatactuel': vehicle.currentState,
        'filliale': vehicle.subsidiary,
        'departement': vehicle.department,
        'direction': vehicle.direction,
        'appartenance': vehicle.ownership,
        'appartenanceconducteur': vehicle.driverOwnership,
        'service': vehicle.service,
        'matriculeConducteur': vehicle.driverRegistration,
        'lourd': vehicle.heavy,
        'decision': vehicle.decision,
        'emplacement': vehicle.location,
        'perimetre': vehicle.perimeter,
        // Preserve the full local-first model for round-tripping.
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
