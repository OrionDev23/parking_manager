import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'sync_engine.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

typedef SyncOperationHandler = Future<void> Function(SyncOperation operation);

/// Drains the local SQLite outbox while an internet connection is available.
/// A SQLite lease prevents independent engine instances from draining the same
/// company's queue or recovering one another's in-flight operations.
class AppwriteSyncEngine implements SyncEngine {
  static const _leaseDuration = Duration(minutes: 2);
  static const _leaseRenewInterval = Duration(seconds: 30);

  final SyncQueue queue;
  final String companyId;
  final Map<String, SyncOperationHandler> handlers;
  final InternetConnection _connection;
  late final String _ownerId =
      '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

  StreamSubscription<InternetStatus>? _subscription;
  Timer? _retryTimer;
  Timer? _leaseTimer;
  bool _running = false;
  bool _syncing = false;
  bool _leaseLost = false;
  bool _leaseRenewing = false;

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

    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(syncNow());
    });

    unawaited(syncNow());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _leaseTimer?.cancel();
    _leaseTimer = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  void _startLeaseRenewal() {
    _leaseLost = false;
    _leaseTimer?.cancel();
    _leaseTimer = Timer.periodic(_leaseRenewInterval, (_) {
      if (_leaseRenewing || _leaseLost) return;
      _leaseRenewing = true;
      unawaited(() async {
        try {
          final renewed = await queue.renewEngineLease(
            companyId: companyId,
            ownerId: _ownerId,
            now: DateTime.now().toUtc(),
            leaseDuration: _leaseDuration,
          );
          if (!renewed) {
            _leaseLost = true;
            debugPrint('[ParcOto Sync] lease lost — stopping this sync batch');
          }
        } catch (error, stackTrace) {
          _leaseLost = true;
          debugPrint('[ParcOto Sync] lease renewal failed: $error\n$stackTrace');
        } finally {
          _leaseRenewing = false;
        }
      }());
    });
  }

  @override
  Future<void> syncNow() async {
    if (!_running || _syncing) {
      debugPrint('[ParcOto Sync] syncNow skipped: running=$_running syncing=$_syncing');
      return;
    }
    _syncing = true;
    var leaseAcquired = false;
    debugPrint('[ParcOto Sync] syncNow started — companyId=$companyId');
    try {
      try {
        final hasInternet = await _connection.hasInternetAccess;
        debugPrint('[ParcOto Sync] hasInternetAccess=$hasInternet');
        if (!hasInternet || !_running) return;
      } catch (error, stackTrace) {
        debugPrint('[ParcOto Sync] connectivity check failed: $error\n$stackTrace');
        return;
      }

      leaseAcquired = await queue.acquireEngineLease(
        companyId: companyId,
        ownerId: _ownerId,
        now: DateTime.now().toUtc(),
        leaseDuration: _leaseDuration,
      );
      if (!leaseAcquired) {
        debugPrint('[ParcOto Sync] another engine owns the company lease; skipping');
        return;
      }
      _startLeaseRenewal();

      // Recovery must happen only after acquiring the company lease; otherwise
      // one engine could reset another engine's active operations.
      await queue.recoverInterrupted(companyId: companyId);
      final operations = await queue.pending(limit: 5000, companyId: companyId);
      debugPrint('[ParcOto Sync] pending operations=${operations.length}');

      final blockedRecords = <String>{};
      for (final operation in operations) {
        if (!_running || _leaseLost) break;
        final recordKey = '${operation.companyId}:${operation.entity}:${operation.entityId}';
        if (blockedRecords.contains(recordKey)) continue;
        if (operation.status == SyncOperationStatus.conflict) {
          blockedRecords.add(recordKey);
          debugPrint('[ParcOto Sync] blocked by unresolved conflict: ${operation.entity} id=${operation.entityId}');
          continue;
        }
        final handler = handlers[operation.entity];
        if (handler == null) {
          debugPrint('[ParcOto Sync] no handler for entity=${operation.entity}; operation left pending');
          blockedRecords.add(recordKey);
          continue;
        }

        try {
          await queue.markProcessing(operation.id);
          await handler(operation);
          // If the lease expired while the remote request was in flight, do
          // not acknowledge the operation. The next lease owner will recover
          // and retry it; handlers are designed to be idempotent.
          if (_leaseLost) {
            debugPrint('[ParcOto Sync] lease lost during remote write; leaving operation for recovery');
            break;
          }
          await queue.markCompleted(operation.id);
          debugPrint('[ParcOto Sync] SUCCESS ${operation.entity} ${operation.type.name} id=${operation.entityId}');
        } on AppwriteException catch (error, stackTrace) {
          debugPrint('[ParcOto Sync] APPWRITE ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId} code=${error.code} type=${error.type} message=${error.message}\n$stackTrace');
          if (error.code == 409) {
            await queue.markConflict(
              operation.id,
              reason: 'Appwrite ${error.code} (${error.type ?? 'unknown'}): ${error.message ?? 'Conflit distant'}',
            );
          } else {
            await queue.markFailed(operation.id);
          }
          blockedRecords.add(recordKey);
        } catch (error, stackTrace) {
          debugPrint('[ParcOto Sync] ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId}: $error\n$stackTrace');
          await queue.markFailed(operation.id);
          blockedRecords.add(recordKey);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('[ParcOto Sync] syncNow crashed: $error\n$stackTrace');
    } finally {
      _leaseTimer?.cancel();
      _leaseTimer = null;
      if (leaseAcquired) {
        try {
          await queue.releaseEngineLease(companyId: companyId, ownerId: _ownerId);
        } catch (error, stackTrace) {
          debugPrint('[ParcOto Sync] lease release failed: $error\n$stackTrace');
        }
      }
      _syncing = false;
      debugPrint('[ParcOto Sync] syncNow finished');
    }
  }
}
