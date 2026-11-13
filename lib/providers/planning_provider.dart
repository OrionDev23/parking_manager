import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/planning.dart';

import '../main.dart';
import 'client_database.dart';

class PlanningProvider extends ChangeNotifier {
  static void invalidateSessionCache() {
    _cacheGeneration++;
    _cacheCompanyId = null;
    plannings.clear();
    downloadedPlanning = false;
    downloadingPlanning = false;
  }


  static Map<String, Planning> plannings = {};
  static bool downloadedPlanning = false;
  static bool downloadingPlanning = false;
  static const String _cacheEntity = 'planning';

  static int _cacheGeneration = 0;

  static bool _isCurrentCompany(String companyId, int generation) =>
      vehicleServices.companyId == companyId && _cacheGeneration == generation;

  static String? _cacheCompanyId;

  static void _ensureCompanyCache() {
    final companyId = vehicleServices.companyId;
    if (_cacheCompanyId == companyId) return;
    _cacheGeneration++;
    plannings.clear();
    downloadedPlanning = false;
    downloadingPlanning = false;
    _cacheCompanyId = companyId;
  }

  PlanningProvider() {
    _ensureCompanyCache();
    if (!downloadedPlanning && !downloadingPlanning) {
      refreshPlannings();
    }
  }

  List<Planning> _readLocalPlannings() {
    final rows = vehicleServices.localDatabase.readLegacyCache(
      companyId: vehicleServices.companyId,
      entity: _cacheEntity,
    );
    final result = <Planning>[];
    for (final row in rows) {
      try {
        result.add(Planning.fromJson(row));
      } catch (error) {
        debugPrint('[ParcOto Planning] invalid cached row ignored: $error');
      }
    }
    return result;
  }

  Future<void> refreshPlannings() async {
    if (downloadingPlanning) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingPlanning = true;
    try {
      final cached = _readLocalPlannings();
      if (!_isCurrentCompany(companyId, generation)) return;
      if (cached.isNotEmpty) { plannings = {for (final item in cached) item.id: item}; downloadedPlanning = true; notifyListeners(); }
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) debugPrint('[ParcOto Planning] local cache read failed: $error');
    }
    try {
      final database = DatabaseGetter.database;
      if (database == null) throw StateError('Appwrite database unavailable');
      final value = await database.listRows(databaseId: databaseId, tableId: planningID, queries: [Query.limit(5000)]);
      if (!_isCurrentCompany(companyId, generation)) return;
      final refreshed = <String, Planning>{};
      for (final row in value.rows) {
        final payload = <String, dynamic>{...row.data, r'$id': row.$id, r'$createdAt': row.$createdAt, r'$updatedAt': row.$updatedAt};
        try {
          final item = Planning.fromJson(payload); refreshed[item.id] = item;
          vehicleServices.localDatabase.cacheLegacyRow(companyId: companyId, entity: _cacheEntity, entityId: row.$id, payload: payload);
        } catch (error) { debugPrint('[ParcOto Planning] remote row ignored: $error'); }
      }
      if (!_isCurrentCompany(companyId, generation)) return;
      plannings = refreshed; downloadedPlanning = true;
    } catch (error, stackTrace) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedPlanning = plannings.isNotEmpty;
        debugPrint('[ParcOto Planning] remote refresh failed: $error');
        if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) { downloadingPlanning = false; notifyListeners(); }
    }
  }

  Future<int> getPlanningCount() async {
    if (!downloadedPlanning && !downloadingPlanning) {
      await refreshPlannings();
    } else {
      while (downloadingPlanning) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return plannings.length;
  }

  static List<String> removedPlanDocs = [];

  Future<List<Planning>> getPlanningBeforeTime(DateTime expiration) async {
    removedPlanDocs = prefs.getStringList('removedPlanning') ?? [];
    while (downloadingPlanning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!downloadedPlanning) {
      await refreshPlannings();
    }
    return plannings.values
        .where(
          (element) =>
              element.startTime.isBefore(expiration) &&
              !removedPlanDocs.contains(element.id),
        )
        .toList(growable: false);
  }
}
