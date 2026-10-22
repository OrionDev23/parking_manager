import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/planning.dart';

import '../main.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class PlanningProvider extends ChangeNotifier {
  static Map<String, Planning> plannings = {};
  static bool downloadedPlanning = false;
  static bool downloadingPlanning = false;
  static const String _cacheEntity = 'planning';

  PlanningProvider() {
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
    downloadingPlanning = true;

    // Show cached data immediately; the network refresh below is best-effort.
    try {
      final cached = _readLocalPlannings();
      if (cached.isNotEmpty) {
        plannings = {for (final item in cached) item.id: item};
        downloadedPlanning = true;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('[ParcOto Planning] local cache read failed: $error');
    }

    try {
      final database = DatabaseGetter.database;
      if (database == null) {
        throw StateError('Appwrite database unavailable');
      }
      final value = await database.listRows(
        databaseId: databaseId,
        tableId: planningID,
        queries: [Query.limit(5000)],
      );
      final refreshed = <String, Planning>{};
      for (final row in value.rows) {
        final payload = <String, dynamic>{
          ...row.data,
          r'$id': row.$id,
          r'$createdAt': row.$createdAt,
          r'$updatedAt': row.$updatedAt,
        };
        try {
          final planning = Planning.fromJson(payload);
          refreshed[planning.id] = planning;
          vehicleServices.localDatabase.cacheLegacyRow(
            companyId: vehicleServices.companyId,
            entity: _cacheEntity,
            entityId: row.$id,
            payload: payload,
          );
        } catch (error) {
          debugPrint('[ParcOto Planning] remote row ignored: $error');
        }
      }
      plannings = refreshed;
      downloadedPlanning = true;
    } catch (error, stackTrace) {
      // Offline startup remains usable when a local snapshot exists.
      downloadedPlanning = plannings.isNotEmpty;
      debugPrint('[ParcOto Planning] remote refresh failed: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    } finally {
      downloadingPlanning = false;
      notifyListeners();
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
        .where((element) =>
            element.startTime.isBefore(expiration) &&
            !removedPlanDocs.contains(element.id))
        .toList(growable: false);
  }
}
