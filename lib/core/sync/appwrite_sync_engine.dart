import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'sync_engine.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

typedef SyncOperationHandler = Future<void> Function(SyncOperation operation);

/// Drains the local SQLite outbox while an internet connection is available.
/// Operations are sent directly to remote sources, never back through
/// repositories, so syncing cannot enqueue duplicate operations.
class AppwriteSyncEngine implements SyncEngine {
  final SyncQueue queue;
  final String companyId;
  final Map<String, SyncOperationHandler> handlers;
  final InternetConnection _connection;

  StreamSubscription<InternetStatus>? _subscription;
  Timer? _retryTimer;
  bool _running = false;
  bool _syncing = false;

  AppwriteSyncEngine({
    required this.queue,
    required this.companyId,
    required this.handlers,
    InternetConnection? connection,
  }) : _connection = connection ?? InternetConnection();

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    debugPrint('[ParcOto Sync] start() — companyId=$companyId, handlers=${handlers.keys.toList()}');

    _subscription = _connection.onStatusChange.listen((status) {
      debugPrint('[ParcOto Sync] connectivity status=$status');
      if (status == InternetStatus.connected) {
        unawaited(syncNow());
      }
    });

    // Also retry periodically: a server/API failure can occur while the
    // device remains connected, so waiting only for connectivity changes
    // would leave failed operations stuck indefinitely.
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(syncNow());
    });

    // Never wait for network reachability or remote requests during app boot.
    // The UI can start immediately and cached SQLite data remains available.
    unawaited(syncNow());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> syncNow() async {
    if (!_running || _syncing) {
      debugPrint('[ParcOto Sync] syncNow skipped: running=$_running syncing=$_syncing');
      return;
    }
    _syncing = true;
    debugPrint('[ParcOto Sync] syncNow started — companyId=$companyId');
    try {
      try {
        final hasInternet = await _connection.hasInternetAccess;
        debugPrint('[ParcOto Sync] hasInternetAccess=$hasInternet');
        if (!hasInternet) return;
      } catch (error, stackTrace) {
        debugPrint('[ParcOto Sync] connectivity check failed: $error\n$stackTrace');
        // Connectivity checks must never prevent offline startup or crash
        // the background worker.
        return;
      }

      // Take a snapshot so failed operations are not retried in a tight loop
      // during this same run. Failed rows are retried by the next timer/event.
      final operations = await queue.pending(
        limit: 5000,
        companyId: companyId,
      );
      debugPrint('[ParcOto Sync] pending operations=${operations.length}');

      for (final operation in operations) {
        debugPrint('[ParcOto Sync] processing ${operation.entity} ${operation.type.name} id=${operation.entityId} status=${operation.status} attempts=${operation.attempts}');
        if (!_running) break;
        final handler = handlers[operation.entity];
        if (handler == null) {
          await queue.markConflict(operation.id);
          continue;
        }

        try {
          await handler(operation);
          await queue.markCompleted(operation.id);
          debugPrint('[ParcOto Sync] SUCCESS ${operation.entity} ${operation.type.name} id=${operation.entityId}');
        } on AppwriteException catch (error, stackTrace) {
          debugPrint('[ParcOto Sync] APPWRITE ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId} code=${error.code} type=${error.type} message=${error.message}\n$stackTrace');
          if (error.code == 409) {
            // Do not silently overwrite a remote record on an ID conflict.
            await queue.markConflict(operation.id);
          } else {
            await queue.markFailed(operation.id);
          }
        } catch (error, stackTrace) {
          debugPrint('[ParcOto Sync] ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId}: $error\n$stackTrace');
          await queue.markFailed(operation.id);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('[ParcOto Sync] syncNow crashed: $error\n$stackTrace');
    } finally {
      _syncing = false;
      debugPrint('[ParcOto Sync] syncNow finished');
    }
  }
}
