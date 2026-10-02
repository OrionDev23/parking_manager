import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../data/mappers/vehicle_mapper.dart';
import '../domain/entities/vehicle.dart' as domain;
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

  VehicleProvider() {
    if (!downloadedVehicles && !downloadingVehicles) {
      refreshVehicles();
    }
  }

  Future<void> refreshVehicles() async {
    if (downloadingVehicles) return;

    downloadingVehicles = true;
    vehicles.clear();

    try {
      var localVehicles = await vehicleServices.repository.getVehicles();

      if (localVehicles.isEmpty) {
        await _bootstrapLegacyVehicles();
        localVehicles = await vehicleServices.repository.getVehicles();
      }

      for (final vehicle in localVehicles) {
        final legacy = VehicleMapper.toLegacy(vehicle);
        vehicles[legacy.id] = legacy;
      }
      downloadedVehicles = true;
    } catch (_) {
      downloadedVehicles = false;
    } finally {
      downloadingVehicles = false;
      notifyListeners();
    }
  }

  Future<void> _bootstrapLegacyVehicles() async {
    final result = await DatabaseGetter.database!.listRows(
      databaseId: databaseId,
      tableId: vehiculeid,
      queries: [
        Query.limit(DatabaseGetter.limits['vehicles'] ?? 500),
      ],
    );

    final companyId = project ?? 'local';
    for (final row in result.rows) {
      final legacy = row.convertTo((data) => Vehicle.fromJson(data));
      final domainVehicle = VehicleMapper.toDomain(
        legacy,
        companyId: companyId,
      );
      await vehicleServices.repository.createVehicle(domainVehicle);
    }
  }

  Future<void> refreshDocuments() async {
    if (downloadingDocuments) return;
    downloadingDocuments = true;
    documentsVehicules.clear();

    await DatabaseGetter.database!
        .listRows(
          databaseId: databaseId,
          tableId: vehicDoc,
          queries: [Query.limit(5000)],
        )
        .then((value) {
          for (final row in value.rows) {
            documentsVehicules[row.$id] =
                row.convertTo((data) => DocumentVehicle.fromJson(data));
          }
          downloadedDocuments = true;
        })
        .onError((error, stackTrace) {
          downloadedDocuments = false;
        });

    downloadingDocuments = false;
    notifyListeners();
  }

  Future<void> refreshStates() async {
    if (downloadingStates) return;
    downloadingStates = true;
    etats.clear();

    await DatabaseGetter.database!
        .listRows(
          databaseId: databaseId,
          tableId: etatId,
          queries: [Query.limit(5000)],
        )
        .then((value) {
          for (final row in value.rows) {
            etats[row.$id] =
                row.convertTo((data) => Etat.fromJson(data));
          }
          downloadedStates = true;
        })
        .onError((error, stackTrace) {
          downloadedStates = false;
        });

    downloadingStates = false;
    notifyListeners();
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
              Query.lessThanEqual(
                'date_expiration',
                dateToIntJson(expiration),
              ),
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
        VehicleMapper.toDomain(
          legacy,
          companyId: project ?? 'local',
        ),
      );
      return legacy;
    } on AppwriteException {
      return null;
    }
  }
}
