import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../core/services/vehicle_services.dart';
import '../data/mappers/vehicle_mapper.dart';
import '../main.dart';
import '../serializables/vehicle/document_vehicle.dart';
import '../serializables/vehicle/state.dart';
import '../serializables/vehicle/vehicle.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class VehicleProvider extends ChangeNotifier {
  static Map<String, Vehicle> vehicles = {};
  static Map<String, Etat> etats = {};
  static Map<String, DocumentVehicle> documentsVehicules = {};

  static bool downloadedVehicles = false;
  static bool downloadingVehicles = false;
  static bool downloadedDocuments = false;
  static bool downloadingDocuments = false;
  static bool downloadedStates = false;
  static bool downloadingStates = false;

  static int _cacheGeneration = 0;

  static bool _isCurrentCompany(String companyId, int generation) =>
      vehicleServices.companyId == companyId && _cacheGeneration == generation;

  static String? _cacheCompanyId;

  static void _ensureCompanyCache() {
    final companyId = vehicleServices.companyId;
    if (_cacheCompanyId == companyId) return;
    _cacheGeneration++;
    vehicles.clear();
    etats.clear();
    documentsVehicules.clear();
    downloadedVehicles = false;
    downloadingVehicles = false;
    downloadedDocuments = false;
    downloadingDocuments = false;
    downloadedStates = false;
    downloadingStates = false;
    _cacheCompanyId = companyId;
  }

  VehicleProvider() {
    _ensureCompanyCache();
    if (!downloadedVehicles && !downloadingVehicles) {
      refreshVehicles();
    }
    if (!downloadedDocuments && !downloadingDocuments) {
      refreshDocuments();
    }
  }

  Future<void> refreshVehicles() async {
    if (downloadingVehicles) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingVehicles = true;
    vehicles.clear();
    try {
      var localVehicles = await vehicleServices.repository.getVehicles();
      if (!_isCurrentCompany(companyId, generation)) return;
      if (localVehicles.isEmpty) {
        await _bootstrapLegacyVehicles(
          services: vehicleServices,
          companyId: companyId,
          generation: generation,
        );
        if (!_isCurrentCompany(companyId, generation)) return;
        localVehicles = await vehicleServices.repository.getVehicles();
        if (!_isCurrentCompany(companyId, generation)) return;
      }
      vehicles
        ..clear()
        ..addEntries(localVehicles.map((vehicle) {
          final legacy = VehicleMapper.toLegacy(vehicle);
          return MapEntry(legacy.id, legacy);
        }));
      downloadedVehicles = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedVehicles = false;
        debugPrint('[ParcOto Vehicles] refresh failed: $error');
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) {
        downloadingVehicles = false;
        notifyListeners();
      }
    }
  }

  Future<void> _bootstrapLegacyVehicles({
    required VehicleServices services,
    required String companyId,
    required int generation,
  }) async {
    final result = await DatabaseGetter.database!.listRows(
      databaseId: databaseId,
      tableId: vehiculeid,
      queries: [Query.limit(DatabaseGetter.limits['vehicles'] ?? 500)],
    );
    if (!_isCurrentCompany(companyId, generation)) return;
    for (final row in result.rows) {
      if (!_isCurrentCompany(companyId, generation)) return;
      final legacy = row.convertTo((data) => Vehicle.fromJson(data));
      final domainVehicle = VehicleMapper.toDomain(legacy, companyId: companyId);
      await services.seedLocal(domainVehicle);
    }
  }

  Future<void> refreshDocuments() async {
    if (downloadingDocuments) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingDocuments = true;
    documentsVehicules.clear();
    try {
      final value = await DatabaseGetter.database!.listRows(
        databaseId: databaseId, tableId: vehicDoc, queries: [Query.limit(5000)],
      );
      if (!_isCurrentCompany(companyId, generation)) return;
      final refreshed = <String, DocumentVehicle>{};
      for (final row in value.rows) {
        refreshed[row.$id] = row.convertTo((data) => DocumentVehicle.fromJson(data));
      }
      documentsVehicules..clear()..addAll(refreshed);
      downloadedDocuments = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedDocuments = false;
        debugPrint('[ParcOto Vehicle documents] refresh failed: $error');
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) {
        downloadingDocuments = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshStates() async {
    if (downloadingStates) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingStates = true;
    etats.clear();
    try {
      final value = await DatabaseGetter.database!.listRows(
        databaseId: databaseId, tableId: etatId, queries: [Query.limit(5000)],
      );
      if (!_isCurrentCompany(companyId, generation)) return;
      final refreshed = <String, Etat>{};
      for (final row in value.rows) {
        refreshed[row.$id] = row.convertTo((data) => Etat.fromJson(data));
      }
      etats..clear()..addAll(refreshed);
      downloadedStates = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedStates = false;
        debugPrint('[ParcOto Vehicle states] refresh failed: $error');
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) {
        downloadingStates = false;
        notifyListeners();
      }
    }
  }

  Future<int> getVehicleCount() async {
    if (!downloadedVehicles && !downloadingVehicles) {
      await refreshVehicles();
    } else {
      while (downloadingVehicles) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return vehicles.length;
  }

  Future<int> getVehicleDocsCount() async {
    if (!downloadedDocuments && !downloadingDocuments) {
      await refreshDocuments();
    } else {
      while (downloadingDocuments) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return documentsVehicules.length;
  }

  Future<int> getVehicleStatesCount() async {
    if (!downloadedStates && !downloadingStates) {
      await refreshStates();
    } else {
      while (downloadingStates) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return etats.length;
  }

  void addVehicle(Vehicle vehicle) {
    vehicles[vehicle.id] = vehicle;
    notifyListeners();
  }

  void removeVehicle(Vehicle vehicle) {
    vehicles.remove(vehicle.id);
    notifyListeners();
  }

  static List<String> removedVehiDocs = [];

  Future<List<DocumentVehicle>> getDocumentsBeforeTime(
    DateTime expiration,
  ) async {
    removedVehiDocs = prefs.getStringList('removedDocs') ?? [];

    final result = <DocumentVehicle>[];

    while (downloadingDocuments) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (downloadedDocuments) {
      for (final element in documentsVehicules.values) {
        if (element.dateExpiration != null &&
            element.dateExpiration!.isBefore(expiration) &&
            !removedVehiDocs.contains(element.id)) {
          result.add(element);
        }
      }
    } else {
      await DatabaseGetter.database!
          .listRows(
            databaseId: databaseId,
            tableId: vehicDoc,
            queries: [
              Query.lessThanEqual('date_expiration', dateToIntJson(expiration)),
              if (removedVehiDocs.isNotEmpty)
                ...removedVehiDocs.map((e) => Query.notEqual(r'\$id', e)),
            ],
          )
          .then((value) {
            for (final row in value.rows) {
              result.add(
                row.convertTo((data) => DocumentVehicle.fromJson(data)),
              );
            }
          })
          .onError((error, stackTrace) {
            if (kDebugMode) print(stackTrace);
          });
    }

    return result;
  }

  Future<Vehicle?> getVehicle(String docID) async {
    final local = await vehicleServices.repository.getVehicle(docID);
    if (local != null) {
      return VehicleMapper.toLegacy(local);
    }

    try {
      final row = await DatabaseGetter.database!.getRow(
        databaseId: databaseId,
        tableId: vehiculeid,
        rowId: docID,
      );
      final legacy = row.convertTo((data) => Vehicle.fromJson(data));
      await vehicleServices.repository.createVehicle(
        VehicleMapper.toDomain(legacy, companyId: project ?? 'local'),
      );
      return legacy;
    } on AppwriteException {
      return null;
    }
  }
}
