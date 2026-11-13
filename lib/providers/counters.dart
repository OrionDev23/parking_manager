import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';

class DatabaseCounters {
  /// Appwrite returns the total number of matching rows independently from
  /// the page size. A one-row page is therefore enough to retrieve a count.
  /// The previous offset loops repeated the same count request and could loop
  /// indefinitely for tables with at least 5,000 rows.
  Future<int> _countRows({
    required String tableId,
    List<String> filters = const [],
  }) async {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database unavailable while loading dashboard statistics');
    }

    final result = await database.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: [...filters, Query.limit(1)],
    );
    return result.total;
  }

  Future<int> countVehicles({int etat = -1}) async {
    if (VehicleProvider.downloadedVehicles) {
      if (etat == -1) return VehicleProvider.vehicles.length;

      var result = 0;
      for (final vehicle in VehicleProvider.vehicles.values) {
        if ((etat == 0 && vehicle.etatactuel == null) ||
            vehicle.etatactuel == etat) {
          result++;
        }
      }
      return result;
    }

    return _countRows(
      tableId: vehiculeid,
      filters: [
        if (etat != -1) Query.equal('etatactuel', etat),
      ],
    );
  }

  Future<int> countVehiclesWithCondition(List<String> queries) {
    return _countRows(tableId: vehiculeid, filters: queries);
  }

  Future<int> countChauffeurWithCondition(List<String> queries) {
    return _countRows(tableId: chauffeurid, filters: queries);
  }

  Future<int> countChauffeur({int etat = -1}) {
    return _countRows(
      tableId: chauffeurid,
      filters: [
        if (etat != -1) Query.equal('etat', etat),
        if (etat == -1) Query.notEqual('etat', 3),
      ],
    );
  }

  Future<int> countVdocs() {
    return _countRows(tableId: vehicDoc);
  }

  Future<int> countCDocs() {
    return _countRows(tableId: chaufDoc);
  }

  Future<int> countReservation() {
    return _countRows(tableId: planningID);
  }

  Future<int> countLog() {
    return _countRows(tableId: activityId);
  }

  Future<int> countReparation() {
    return _countRows(tableId: reparationId);
  }

  Future<int> countPrestataire() {
    return _countRows(tableId: prestataireId);
  }
}
