import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../main.dart';
import '../serializables/activity.dart';
import 'client_database.dart';

class LogProvider extends ChangeNotifier {
  static Map<String, Activity> activities = {};
  static bool downloadedActivities = false;
  static bool downloadingActivities = false;

  static int _cacheGeneration = 0;

  static bool _isCurrentCompany(String companyId, int generation) =>
      vehicleServices.companyId == companyId && _cacheGeneration == generation;

  static String? _cacheCompanyId;

  static void _ensureCompanyCache() {
    final companyId = vehicleServices.companyId;
    if (_cacheCompanyId == companyId) return;
    _cacheGeneration++;
    activities.clear();
    downloadedActivities = false;
    downloadingActivities = false;
    _cacheCompanyId = companyId;
  }

  LogProvider() {
    _ensureCompanyCache();
    if (!downloadedActivities && !downloadingActivities) {
      refreshLogs();
    }
  }

  Future<void> refreshLogs() async {
    if (downloadingActivities) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingActivities = true;
    try {
      final cached = vehicleServices.localDatabase.readLegacyCache(companyId: companyId, entity: 'activity');
      if (!_isCurrentCompany(companyId, generation)) return;
      final cachedItems = <String, Activity>{};
      for (final payload in cached) {
        try { final item = Activity.fromJson(payload); cachedItems[item.id] = item; }
        catch (error) { debugPrint('[ParcOto Activity] invalid cached row ignored: $error'); }
      }
      activities..clear()..addAll(cachedItems);
      if (activities.isNotEmpty) notifyListeners();
      final database = DatabaseGetter.database;
      if (database == null) throw StateError('Appwrite database unavailable');
      final result = await database.listRows(databaseId: databaseId, tableId: activityId, queries: [Query.limit(5000)]);
      if (!_isCurrentCompany(companyId, generation)) return;
      final refreshed = <String, Activity>{};
      for (final row in result.rows) {
        final payload = <String, dynamic>{...row.data, r'$id': row.$id, r'$createdAt': row.$createdAt, r'$updatedAt': row.$updatedAt};
        try {
          final item = Activity.fromJson(payload); refreshed[item.id] = item;
          vehicleServices.localDatabase.cacheLegacyRow(companyId: companyId, entity: 'activity', entityId: row.$id, payload: payload);
        } catch (error) { debugPrint('[ParcOto Activity] remote row ignored: $error'); }
      }
      if (!_isCurrentCompany(companyId, generation)) return;
      activities..clear()..addAll(refreshed); downloadedActivities = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedActivities = activities.isNotEmpty;
        debugPrint('[ParcOto Activity] refresh failed: $error');
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) { downloadingActivities = false; notifyListeners(); }
    }
  }

  Future<int> getLogCount() async {
    if (!downloadedActivities && !downloadingActivities) {
      await refreshLogs();
    } else {
      while (downloadingActivities) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return activities.length;
  }
}
