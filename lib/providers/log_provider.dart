import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../main.dart';
import '../serializables/activity.dart';
import 'client_database.dart';

class LogProvider extends ChangeNotifier {
  static Map<String, Activity> activities = {};
  static bool downloadedActivities = false;
  static bool downloadingActivities = false;

  LogProvider() {
    if (!downloadedActivities && !downloadingActivities) {
      refreshLogs();
    }
  }

  Future<void> refreshLogs() async {
    if (downloadingActivities) return;
    downloadingActivities = true;

    try {
      final cached = vehicleServices.localDatabase.readLegacyCache(
        companyId: vehicleServices.companyId,
        entity: 'activity',
      );
      for (final payload in cached) {
        try {
          final item = Activity.fromJson(payload);
          activities[item.id] = item;
        } catch (error) {
          debugPrint('[ParcOto Activity] invalid cached row ignored: $error');
        }
      }
      if (activities.isNotEmpty) {
        downloadedActivities = true;
        notifyListeners();
      }

      final database = DatabaseGetter.database;
      if (database == null) throw StateError('Appwrite database unavailable');
      final result = await database.listRows(
        databaseId: databaseId,
        tableId: activityId,
        queries: [Query.limit(5000)],
      );
      final refreshed = <String, Activity>{};
      for (final row in result.rows) {
        final payload = <String, dynamic>{
          ...row.data,
          r'$id': row.$id,
          r'$createdAt': row.$createdAt,
          r'$updatedAt': row.$updatedAt,
        };
        try {
          final activity = Activity.fromJson(payload);
          refreshed[activity.id] = activity;
          vehicleServices.localDatabase.cacheLegacyRow(
            companyId: vehicleServices.companyId,
            entity: 'activity',
            entityId: row.$id,
            payload: payload,
          );
        } catch (error) {
          debugPrint('[ParcOto Activity] remote row ignored: $error');
        }
      }
      activities = refreshed;
      downloadedActivities = true;
    } catch (error) {
      downloadedActivities = activities.isNotEmpty;
      debugPrint('[ParcOto Activity] refresh failed: $error');
    } finally {
      downloadingActivities = false;
      notifyListeners();
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
