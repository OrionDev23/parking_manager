import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';

class DatabaseCounters {
  static final Map<String, Future<int>> _countCache = {};
  static int _cacheTenantRevision = -1;

  /// Clears memoized counts after an explicit dashboard refresh.
  static void invalidateCache() {
    _countCache.clear();
  }

  Future<int> _countRows({
    required String tableId,
    List<String> filters = const [],
  }) {
    final tenantRevision = DatabaseGetter.tenantRevision;
    if (_cacheTenantRevision != tenantRevision) {
      _countCache.clear();
      _cacheTenantRevision = tenantRevision;
    }

    final cacheKey = '$tenantRevision|$tableId|${filters.join('|')}';
    return _countCache.putIfAbsent(cacheKey, () async {
      final database = DatabaseGetter.database;
      if (database == null) {
        throw StateError(
          'Appwrite database unavailable while loading dashboard statistics',
        );
      }

      try {
        final result = await database.listRows(
          databaseId: databaseId,
          tableId: tableId,
          queries: [...filters, Query.limit(1)],
        );
        return result.total;
      } catch (_) {
        // Do not cache failures: a later retry must be able to reach Appwrite.
        _countCache.remove(cacheKey);
        rethrow;
      }
    });
  }
  Future<int> countVehicles({int etat = -1}) {
    if (VehicleProvider.downloadedVehicles) {
      final tenantRevision = DatabaseGetter.tenantRevision;
      if (_cacheTenantRevision != tenantRevision) {
        _countCache.clear();
        _cacheTenantRevision = tenantRevision;
      }
      final cacheKey = '$tenantRevision|localVehicles|$etat';
      return _countCache.putIfAbsent(cacheKey, () async {
        if (etat == -1) return VehicleProvider.vehicles.length;

        var result = 0;
        for (final vehicle in VehicleProvider.vehicles.values) {
          if ((etat == 0 && vehicle.etatactuel == null) ||
              vehicle.etatactuel == etat) {
            result++;
          }
        }
        return result;
      });
    }

    return _countRows(
      tableId: vehiculeid,
      filters: [
        if (etat == 0)
          Query.or([
            Query.isNull('etatactuel'),
            Query.equal('etatactuel', 0),
          ])
        else if (etat != -1)
          Query.equal('etatactuel', etat),
      ],
    );
  }

  Future<int> countVehiclesWithCondition(List<String> queries) {
    return _countRows(tableId: vehiculeid, filters: queries);
  }

  Future<int> countVehiclesInStateAndPerimeter({
    required int state,
    required int perimeter,
  }) {
    return _countRows(
      tableId: vehiculeid,
      filters: [
        if (state == 0)
          Query.or([
            Query.isNull('etatactuel'),
            Query.equal('etatactuel', 0),
          ])
        else
          Query.equal('etatactuel', state),
        Query.equal('perimetre', perimeter),
      ],
    );
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
