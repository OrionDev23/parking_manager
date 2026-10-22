import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../../core/backend/appwrite_backend.dart';
import '../../../core/tenancy/company_context.dart';
import '../../../domain/entities/driver.dart';
import 'remote_driver_source.dart';

class AppwriteDriverSource implements RemoteDriverSource {
  final AppwriteBackend backend;
  final CompanyContext companyContext;
  final String databaseId;
  final String tableId;

  AppwriteDriverSource({
    required this.backend,
    required this.companyContext,
    required this.databaseId,
    required this.tableId,
  });

  Driver _fromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row.data);
    final payload = data['payload'];

    if (payload is String && payload.isNotEmpty) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return Driver.fromMap(decoded);
      }
    }
    if (payload is Map) {
      return Driver.fromMap(Map<String, dynamic>.from(payload));
    }

    final createdAt = DateTime.tryParse(row.$createdAt.toString()) ??
        DateTime.now().toUtc();
    final updatedAt = DateTime.tryParse(row.$updatedAt.toString()) ?? createdAt;
    final rawBirthDate = data['dateNaissance'];
    final birthDate = rawBirthDate is num
        ? _legacyDate(rawBirthDate.toInt())
        : DateTime.tryParse(rawBirthDate?.toString() ?? '');

    return Driver(
      id: row.$id.toString(),
      companyId: data['companyId']?.toString() ?? '',
      siteId: data['siteId']?.toString(),
      firstName: data['prenom']?.toString() ?? '',
      lastName: data['name']?.toString() ?? '',
      registration: data['matricule']?.toString() ?? '',
      email: data['email']?.toString(),
      phone: data['telephone']?.toString(),
      address: data['adresse']?.toString(),
      profession: data['profession']?.toString(),
      birthDate: birthDate,
      createdBy: data['createdBy']?.toString(),
      currentStateId: data['etatactuel']?.toString(),
      state: (data['etat'] as num?)?.toInt() ?? 0,
      subsidiary: data['filliale']?.toString(),
      direction: data['direction']?.toString(),
      department: data['departement']?.toString(),
      vehicleIds: List<String>.from(data['vehicules'] as List? ?? const []),
      service: data['service'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _legacyDate(int milliseconds) =>
      DateTime(2023, 11, 1, 12, 13, 15)
          .add(Duration(milliseconds: milliseconds));

  Map<String, dynamic> _toRow(Driver driver) => {
        'companyId': driver.companyId,
        'siteId': driver.siteId,
        'name': driver.lastName,
        'prenom': driver.firstName,
        'matricule': driver.registration,
        'dateNaissance': driver.birthDate?.difference(DateTime(2023, 11, 1, 12, 13, 15))
                .inMilliseconds,
        'email': driver.email,
        'telephone': driver.phone,
        'adresse': driver.address,
        'createdBy': driver.createdBy,
        'etatactuel': driver.currentStateId,
        'etat': driver.state,
        'filliale': driver.subsidiary,
        'direction': driver.direction,
        'departement': driver.department,
        'profession': driver.profession,
        'vehicules': driver.vehicleIds,
        'service': driver.service,
        'search': _searchText(driver),
        'payload': jsonEncode(driver.toMap()),
      };

  String _searchText(Driver driver) =>
      '${driver.lastName} ${driver.firstName} ${driver.registration} '
      '${driver.email ?? ''} ${driver.phone ?? ''} ${driver.address ?? ''} '
      '${driver.profession ?? ''} ${driver.subsidiary ?? ''} '
      '${driver.direction ?? ''} ${driver.department ?? ''}';

  @override
  Future<List<Driver>> getDrivers({
    String? search,
    int? limit,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final baseQueries = <String>[
      if (includeArchived)
        Query.equal('etat', 3)
      else
        Query.notEqual('etat', 3),
      Query.orderDesc(r'$updatedAt'),
      if (search != null && search.trim().isNotEmpty)
        Query.search('search', search.trim()),
    ];

    Future<List<dynamic>> listRows(List<String> tenantQueries) async {
      final result = await backend.database.listRows(
        databaseId: databaseId,
        tableId: tableId,
        queries: [
          ...baseQueries,
          ...tenantQueries,
          Query.limit(limit ?? 100),
          Query.offset(offset),
        ],
      );
      return result.rows;
    }

    // Tenant isolation is strict: never expose rows without a matching
    // companyId to the active company.
    final rows = await listRows([
      Query.equal('companyId', companyContext.companyId),
    ]);
    rows.sort((a, b) {
      final aDate = DateTime.tryParse(a.$updatedAt.toString()) ?? DateTime(1970);
      final bDate = DateTime.tryParse(b.$updatedAt.toString()) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    final start = offset.clamp(0, rows.length);
    final end = (start + (limit ?? 100)).clamp(start, rows.length);
    return rows
        .sublist(start, end)
        .map<Driver>(_fromRow)
        .toList(growable: false);
  }

  @override
  Future<Driver?> getDriver(String id) async {
    try {
      final row = await backend.database.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
      );
      final rawCompanyId = row.data['companyId']?.toString();
      if (rawCompanyId == null ||
          rawCompanyId.isEmpty ||
          rawCompanyId != companyContext.companyId) {
        return null;
      }
      return _fromRow(row);
    } on AppwriteException catch (error) {
      if (error.code == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Driver> createDriver(Driver driver) async {
    _checkCompany(driver);
    await backend.database.createRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: driver.id,
      data: _toRow(driver),
    );
    return driver;
  }

  @override
  Future<Driver> updateDriver(Driver driver) async {
    _checkCompany(driver);
    final existing = await getDriver(driver.id);
    if (existing == null) {
      throw StateError('Driver not found in the active company.');
    }
    await backend.database.updateRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: driver.id,
      data: _toRow(driver),
    );
    return driver;
  }

  @override
  Future<void> deleteDriver(String id) async {
    final existing = await getDriver(id);
    if (existing == null) return;
    _checkCompany(existing);
    await backend.database.deleteRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: id,
    );
  }

  void _checkCompany(Driver driver) {
    if (driver.companyId != companyContext.companyId) {
      throw StateError('Driver company does not match the active company.');
    }
  }
}
