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
    if (payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return Driver.fromMap(decoded);
    }
    if (payload is Map) return Driver.fromMap(Map<String, dynamic>.from(payload));
    throw const FormatException('Driver remote payload is missing.');
  }

  Map<String, dynamic> _toRow(Driver driver) => {
    'companyId': driver.companyId,
    'siteId': driver.siteId,
    'name': driver.lastName,
    'prenom': driver.firstName,
    'matricule': driver.registration,
    'email': driver.email,
    'telephone': driver.phone,
    'etat': driver.state,
    'payload': jsonEncode(driver.toMap()),
  };

  @override
  Future<List<Driver>> getDrivers({
    String? search,
    int? limit,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final queries = <String>[
      Query.equal('companyId', companyContext.companyId),
      if (!includeArchived) Query.notEqual('etat', 3),
      Query.orderDesc(r'$updatedAt'),
      Query.limit(limit ?? 100),
      Query.offset(offset),
      if (search != null && search.trim().isNotEmpty)
        Query.search('search', search.trim()),
    ];
    final result = await backend.database.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: queries,
    );
    return result.rows.map<Driver>(_fromRow).toList(growable: false);
  }

  @override
  Future<Driver?> getDriver(String id) async {
    try {
      final row = await backend.database.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
      );
      final driver = _fromRow(row);
      return driver.companyId == companyContext.companyId ? driver : null;
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
    final driver = await getDriver(id);
    if (driver == null) return;
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
