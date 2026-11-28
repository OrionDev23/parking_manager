import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/client_database.dart';

/// Synchronizes dismissed operational alerts between this device and the
/// authenticated Appwrite account. The local cache remains the offline source
/// of truth when Appwrite cannot be reached.
class NotificationDismissalService {
  NotificationDismissalService._();

  static const String _accountPreferenceKey =
      'parcoto_notification_dismissals_v1';
  static const int _maxDismissedIdsPerCompany = 250;

  static const Map<int, String> _localPreferenceKeys = {
    0: 'removedDocs',
    1: 'removedCondDocs',
    2: 'removedPlanning',
  };

  static String _token(int type, String id) => '$type:$id';

  static bool _isCurrentAccount({
    required String companyId,
    required String userId,
  }) {
    return DatabaseGetter.activeCompanyId == companyId &&
        DatabaseGetter.user?.$id == userId;
  }

  static Set<String> _readLocalTokens(SharedPreferences local) {
    final result = <String>{};
    for (final entry in _localPreferenceKeys.entries) {
      final values = local.getStringList(
            userScopedPreferenceKey(entry.value),
          ) ??
          const <String>[];
      result.addAll(values.map((id) => _token(entry.key, id)));
    }
    return result;
  }

  static Future<void> _writeLocalTokens(
    SharedPreferences local,
    Iterable<String> tokens,
  ) async {
    final idsByType = <int, List<String>>{
      for (final type in _localPreferenceKeys.keys) type: <String>[],
    };

    for (final token in tokens) {
      final separator = token.indexOf(':');
      if (separator <= 0 || separator == token.length - 1) continue;
      final type = int.tryParse(token.substring(0, separator));
      final id = token.substring(separator + 1);
      if (type == null || !idsByType.containsKey(type)) continue;
      if (!idsByType[type]!.contains(id)) idsByType[type]!.add(id);
    }

    for (final entry in _localPreferenceKeys.entries) {
      await local.setStringList(
        userScopedPreferenceKey(entry.value),
        idsByType[entry.key]!,
      );
    }
  }

  static Map<String, dynamic> _companyBuckets(Map<String, dynamic> prefs) {
    final raw = prefs[_accountPreferenceKey];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static List<String> _remoteTokens(
    Map<String, dynamic> companyBuckets,
    String companyId,
  ) {
    final raw = companyBuckets[companyId];
    if (raw is! List) return const <String>[];
    return raw.whereType<String>().toList(growable: false);
  }

  static List<String> _bounded(Iterable<String> values) {
    final unique = <String>{}..addAll(values);
    final result = unique.toList(growable: true);
    if (result.length > _maxDismissedIdsPerCompany) {
      result.removeRange(0, result.length - _maxDismissedIdsPerCompany);
    }
    return result;
  }

  /// Pulls account-level dismissals, merges them with local offline changes,
  /// then writes the merged state back to both stores.
  static Future<void> restoreFromCloud({
    required String companyId,
    required String userId,
  }) async {
    late final SharedPreferences local;
    try {
      local = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }

    if (!_isCurrentAccount(companyId: companyId, userId: userId)) return;
    final localTokens = _readLocalTokens(local);
    final account = DatabaseGetter.account;
    if (account == null) return;

    try {
      final snapshot = await account.getPrefs();
      if (!_isCurrentAccount(companyId: companyId, userId: userId)) return;

      final currentPrefs = Map<String, dynamic>.from(snapshot.data);
      final buckets = _companyBuckets(currentPrefs);
      final remoteTokens = _remoteTokens(buckets, companyId);
      final merged = _bounded([
        ...remoteTokens,
        ...localTokens,
      ]);

      await _writeLocalTokens(local, merged);

      if (merged.length != remoteTokens.length ||
          !merged.toSet().containsAll(remoteTokens)) {
        buckets[companyId] = merged;
        currentPrefs[_accountPreferenceKey] = buckets;
        if (_isCurrentAccount(companyId: companyId, userId: userId)) {
          await account.updatePrefs(prefs: currentPrefs);
        }
      }
    } catch (_) {
      // Local dismissal state remains available when the user is offline or
      // Appwrite temporarily rejects a preferences request.
    }
  }

  /// Pushes a dismissal after the caller has saved it locally. Existing
  /// account preferences are preserved because updatePrefs replaces the
  /// complete preference object.
  static Future<void> syncDismissal({
    required String companyId,
    required String userId,
    required int type,
    required String id,
  }) async {
    if (!_localPreferenceKeys.containsKey(type) ||
        !_isCurrentAccount(companyId: companyId, userId: userId)) {
      return;
    }

    final account = DatabaseGetter.account;
    if (account == null) return;

    try {
      final snapshot = await account.getPrefs();
      if (!_isCurrentAccount(companyId: companyId, userId: userId)) return;

      final currentPrefs = Map<String, dynamic>.from(snapshot.data);
      final buckets = _companyBuckets(currentPrefs);
      final remoteTokens = _remoteTokens(buckets, companyId);
      final local = await SharedPreferences.getInstance();
      final localTokens = _readLocalTokens(local);
      final merged = _bounded([
        ...remoteTokens,
        ...localTokens,
        _token(type, id),
      ]);

      buckets[companyId] = merged;
      currentPrefs[_accountPreferenceKey] = buckets;
      if (_isCurrentAccount(companyId: companyId, userId: userId)) {
        await account.updatePrefs(prefs: currentPrefs);
      }
    } catch (_) {
      // The local write has already succeeded; a later refresh retries sync.
    }
  }
}
