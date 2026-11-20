import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/serializables/vehicle/vehicle.dart';

class DatabaseCounters {
  static const Duration _cacheTtl = Duration(seconds: 15);
  static final Map<String, _CachedCount> _countCache = {};
  static int _cacheTenantRevision = -1;

  // These tables were verified in the active Appwrite project and expose a
  // companyId column. Never count a tenant table without an explicit tenant
  // predicate just because its legacy table permissions happen to allow it.
  static const Set<String> _companyScopedCountTables = {
    chauffeurid,
    vehicDoc,
    chaufDoc,
    planningID,
    activityId,
    reparationId,
    prestataireId,
  };

  /// Clears memoized counts after an explicit dashboard refresh.
  static void invalidateCache() {
    _countCache.clear();
  }

  String _cacheKey(String source) {
    final revision = DatabaseGetter.tenantRevision;
    if (_cacheTenantRevision != revision) {
      _countCache.clear();
      _cacheTenantRevision = revision;
    }
    return '$revision|${DatabaseGetter.activeCompanyId ?? 'no-company'}|$source';
  }

  Future<int> _countRows({
    required String tableId,
    List<String> filters = const [],
  }) {
    final companyId = DatabaseGetter.activeCompanyId;
    if (_companyScopedCountTables.contains(tableId) &&
        (companyId == null || companyId.isEmpty)) {
      return Future<int>.error(
        StateError('No active company context is selected.'),
      );
    }

    final tenantFilter = _companyScopedCountTables.contains(tableId)
        ? [Query.equal('companyId', companyId!)]
        : const <String>[];
    final cacheKey = _cacheKey(
      'rows|$tableId|${[...tenantFilter, ...filters].join('|')}',
    );
    final now = DateTime.now();
    final cached = _countCache[cacheKey];
    if (cached != null && now.difference(cached.createdAt) < _cacheTtl) {
      return cached.future;
    }
    _countCache.remove(cacheKey);

    late final Future<int> future;
    future = () async {
      try {
        final database = DatabaseGetter.database;
        if (database == null) {
          throw StateError(
            'Appwrite database unavailable while loading dashboard statistics',
          );
        }
        final result = await database
            .listRows(
              databaseId: databaseId,
              tableId: tableId,
              queries: [
                ...tenantFilter,
                ...filters,
                Query.limit(1),
              ],
            )
            .timeout(const Duration(seconds: 20));
        return result.total;
      } catch (_) {
        if (identical(_countCache[cacheKey]?.future, future)) {
          _countCache.remove(cacheKey);
        }
        rethrow;
      }
    }();
    _countCache[cacheKey] = _CachedCount(now, future);
    return future;
  }

  Future<List<Vehicle>> _loadActiveCompanyVehicles() async {
    final provider = VehicleProvider();
    try {
      await provider.getVehicleCount();
      if (!VehicleProvider.downloadedVehicles) {
        throw StateError(
          'Vehicle statistics are unavailable until the active company vehicle cache is loaded.',
        );
      }
      return List<Vehicle>.unmodifiable(VehicleProvider.vehicles.values);
    } finally {
      provider.dispose();
    }
  }

  Future<int> countVehicles({int etat = -1}) async {
    final cacheKey = _cacheKey('vehicles|$etat');
    final now = DateTime.now();
    final cached = _countCache[cacheKey];
    if (cached != null && now.difference(cached.createdAt) < _cacheTtl) {
      return cached.future;
    }
    _countCache.remove(cacheKey);

    late final Future<int> future;
    future = () async {
      try {
        final vehicles = await _loadActiveCompanyVehicles();
        if (etat == -1) return vehicles.length;
        return vehicles.where((vehicle) {
          return (etat == 0 && vehicle.etatactuel == null) ||
              vehicle.etatactuel == etat;
        }).length;
      } catch (_) {
        if (identical(_countCache[cacheKey]?.future, future)) {
          _countCache.remove(cacheKey);
        }
        rethrow;
      }
    }();
    _countCache[cacheKey] = _CachedCount(now, future);
    return future;
  }

  Future<int> countVehiclesWithCondition(List<String> queries) async {
    final vehicles = await _loadActiveCompanyVehicles();
    final decoded = queries.map<Map<String, dynamic>>((query) {
      final value = jsonDecode(query);
      if (value is! Map) {
        throw const FormatException('Unsupported vehicle count query.');
      }
      return Map<String, dynamic>.from(value);
    }).toList(growable: false);

    return vehicles.where((vehicle) {
      final data = vehicle.toJson();
      return decoded.every((query) => _matchesVehicleQuery(data, query));
    }).length;
  }

  Future<int> countVehiclesInStateAndPerimeter({
    required int state,
    required int perimeter,
  }) {
    return countVehiclesWithCondition([
      if (state == 0)
        Query.or([
          Query.isNull('etatactuel'),
          Query.equal('etatactuel', 0),
        ])
      else
        Query.equal('etatactuel', state),
      Query.equal('perimetre', perimeter),
    ]);
  }

  bool _matchesVehicleQuery(
    Map<String, dynamic> data,
    Map<String, dynamic> query,
  ) {
    final method = query['method']?.toString();
    final attribute = query['attribute']?.toString();
    final rawValues = query['values'];
    final values = rawValues is List ? rawValues : [rawValues];

    if (method == 'or' || method == 'and') {
      final nested = values.map((value) {
        if (value is String) {
          final decoded = jsonDecode(value);
          if (decoded is! Map) {
            throw const FormatException('Unsupported nested vehicle query.');
          }
          return Map<String, dynamic>.from(decoded);
        }
        if (value is Map) return Map<String, dynamic>.from(value);
        throw const FormatException('Unsupported nested vehicle query.');
      }).toList(growable: false);
      return method == 'or'
          ? nested.any((item) => _matchesVehicleQuery(data, item))
          : nested.every((item) => _matchesVehicleQuery(data, item));
    }

    if (attribute == null || attribute.isEmpty) {
      throw const FormatException('Vehicle count query has no attribute.');
    }

    final current = data[attribute];
    switch (method) {
      case 'equal':
        return values.contains(current);
      case 'notEqual':
        return current != null && !values.contains(current);
      case 'isNull':
        return current == null;
      case 'isNotNull':
        return current != null;
      case 'contains':
        if (current is Iterable) {
          return values.any((value) => current.contains(value));
        }
        final text = current?.toString();
        return text != null &&
            values.any((value) => text.contains(value.toString()));
      case 'startsWith':
        final text = current?.toString();
        return text != null &&
            values.any((value) => text.startsWith(value.toString()));
      case 'endsWith':
        final text = current?.toString();
        return text != null &&
            values.any((value) => text.endsWith(value.toString()));
      case 'search':
        final text = current?.toString().toLowerCase();
        return text != null &&
            values.any(
              (value) => text.contains(value.toString().toLowerCase()),
            );
      default:
        throw FormatException(
          'Unsupported vehicle count query method: $method',
        );
    }
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

  Future<int> countVdocs() => _countRows(tableId: vehicDoc);

  Future<int> countCDocs() => _countRows(tableId: chaufDoc);

  Future<int> countReservation() => _countRows(tableId: planningID);

  Future<int> countLog() => _countRows(tableId: activityId);

  Future<int> countReparation() => countReparations();

  Future<int> countReparations({int etat = -1}) {
    return _countRows(
      tableId: reparationId,
      filters: [
        if (etat != -1) Query.equal('etat', etat),
      ],
    );
  }

  Future<int> countPrestataire() => _countRows(tableId: prestataireId);
}

class _CachedCount {
  final DateTime createdAt;
  final Future<int> future;

  const _CachedCount(this.createdAt, this.future);
}
