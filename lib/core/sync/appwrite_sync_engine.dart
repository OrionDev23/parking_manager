import 'dart:async';

import 'package:appwrite/appwrite.dart';
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

    _subscription = _connection.onStatusChange.listen((status) {
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

    if (await _connection.hasInternetAccess) {
      await syncNow();
    }
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
    if (!_running || _syncing) return;
    _syncing = true;
    try {
      if (!await _connection.hasInternetAccess) return;

      // Take a snapshot so failed operations are not retried in a tight loop
      // during this same run. Failed rows are retried by the next timer/event.
      final operations = await queue.pending(
        limit: 5000,
        companyId: companyId,
      );

      for (final operation in operations) {
        if (!_running) break;
        final handler = handlers[operation.entity];
        if (handler == null) {
          await queue.markConflict(operation.id);
          continue;
        }

        try {
          await handler(operation);
          await queue.markCompleted(operation.id);
        } on AppwriteException catch (error) {
          if (error.code == 409) {
            // Do not silently overwrite a remote record on an ID conflict.
            await queue.markConflict(operation.id);
          } else {
            await queue.markFailed(operation.id);
          }
        } catch (_) {
          await queue.markFailed(operation.id);
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
