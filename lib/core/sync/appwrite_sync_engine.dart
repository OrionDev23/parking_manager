import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../tenancy/tenant_resource_api.dart';
import 'sync_engine.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

typedef SyncOperationHandler = Future<void> Function(SyncOperation operation);
typedef SyncPullHandler = Future<void> Function();

/// Drains the local SQLite outbox while an internet connection is available.
/// A SQLite lease prevents independent engine instances from draining the same
/// company's queue or recovering one another's in-flight operations.
class AppwriteSyncEngine implements SyncEngine {
  static const _leaseDuration = Duration(minutes: 2);
  static const _leaseRenewInterval = Duration(seconds: 30);

  final SyncQueue queue;
  final String companyId;
  final Map<String, SyncOperationHandler> handlers;
  final Map<String, SyncPullHandler> pullHandlers;
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
  Completer<void>? _syncCompletion;

  AppwriteSyncEngine({
    required this.queue,
    required this.companyId,
    required this.handlers,
    this.pullHandlers = const {},
    InternetConnection? connection,
  }) : _connection = connection ?? InternetConnection();

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    debugPrint(
      '[ParcOto Sync] start() — companyId=$companyId, handlers=${handlers.keys.toList()}',
    );

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
    // Do not swap the global Appwrite project while a previous tenant's
    // remote request is still running.
    await _syncCompletion?.future;
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
          debugPrint(
            '[ParcOto Sync] lease renewal failed: $error\n$stackTrace',
          );
        } finally {
          _leaseRenewing = false;
        }
      }());
    });
  }

  @override
  Future<void> _markFailedWithBackoff(
    SyncOperation operation, {
    required String errorCode,
    required String safeMessage,
  }) async {
    final exponent = operation.attempts.clamp(0, 10);
    final baseSeconds = (5 * (1 << exponent)).clamp(5, 3600).toInt();
    final jitterWindow = baseSeconds ~/ 5;
    final stableSeed = operation.id.codeUnits.fold<int>(
      0,
      (sum, unit) => (sum + unit) & 0x7fffffff,
    );
    final jitter = jitterWindow == 0 ? 0 : stableSeed % (jitterWindow + 1);
    final delaySeconds = (baseSeconds + jitter).clamp(1, 3600).toInt();

    await queue.markFailed(
      operation.id,
      errorCode: errorCode,
      errorMessage: safeMessage,
      nextAttemptAt: DateTime.now().toUtc().add(
        Duration(seconds: delaySeconds),
      ),
    );
  }

  Future<void> syncNow() async {
    if (!_running || _syncing) {
      debugPrint(
        '[ParcOto Sync] syncNow skipped: running=$_running syncing=$_syncing',
      );
      return;
    }
    _syncing = true;
    _syncCompletion = Completer<void>();
    var leaseAcquired = false;
    debugPrint('[ParcOto Sync] syncNow started — companyId=$companyId');
    try {
      try {
        final hasInternet = await _connection.hasInternetAccess;
        debugPrint('[ParcOto Sync] hasInternetAccess=$hasInternet');
        if (!hasInternet || !_running) return;
      } catch (error, stackTrace) {
        debugPrint(
          '[ParcOto Sync] connectivity check failed: $error\n$stackTrace',
        );
        return;
      }

      leaseAcquired = await queue.acquireEngineLease(
        companyId: companyId,
        ownerId: _ownerId,
        now: DateTime.now().toUtc(),
        leaseDuration: _leaseDuration,
      );
      if (!leaseAcquired) {
        debugPrint(
          '[ParcOto Sync] another engine owns the company lease; skipping',
        );
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
        if (operation.companyId != companyId) {
          await queue.markConflict(
            operation.id,
            reason:
                'Tenant mismatch: queued for ${operation.companyId}, engine is scoped to $companyId.',
          );
          debugPrint(
            '[ParcOto Sync] SECURITY BLOCK tenant mismatch operation=${operation.id} '
            'operationCompany=${operation.companyId} engineCompany=$companyId',
          );
          continue;
        }
        final recordKey =
            '${operation.companyId}:${operation.entity}:${operation.entityId}';
        if (blockedRecords.contains(recordKey)) continue;
        final isRecoveredUnknownAction =
            operation.status == SyncOperationStatus.conflict &&
            operation.entity == 'vehicle' &&
            operation.type == SyncOperationType.create &&
            (operation.conflictReason ?? '').contains('Unknown action');
        if (isRecoveredUnknownAction) {
          // This exact permanent rejection was caused by the old tenant API
          // deployment not recognizing the create action. The server hotfix
          // is now active; retry this existing idempotent vehicle create
          // instead of leaving it blocked forever in SQLite.
          await queue.retryConflict(operation.id);
          debugPrint(
            '[ParcOto Sync] retrying legacy unknown-action vehicle create '
            'after tenant API deployment fix: operationId=${operation.id} '
            'entityId=${operation.entityId}',
          );
        } else if (operation.status == SyncOperationStatus.conflict) {
          blockedRecords.add(recordKey);
          debugPrint(
            '[ParcOto Sync] unresolved conflict: '
            'entity=${operation.entity} type=${operation.type.name} '
            'entityId=${operation.entityId} operationId=${operation.id} '
            'attempts=${operation.attempts} '
            'conflictedAt=${operation.conflictedAt?.toIso8601String() ?? 'unknown'} '
            'reason=${operation.conflictReason ?? 'not recorded'}',
          );
          continue;
        }
        final handler = handlers[operation.entity];
        if (handler == null) {
          debugPrint(
            '[ParcOto Sync] no handler for entity=${operation.entity}; operation left pending',
          );
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
            debugPrint(
              '[ParcOto Sync] lease lost during remote write; leaving operation for recovery',
            );
            break;
          }
          await queue.markCompleted(operation.id);
          debugPrint(
            '[ParcOto Sync] SUCCESS ${operation.entity} ${operation.type.name} id=${operation.entityId}',
          );
        } on TenantResourceException catch (error, stackTrace) {
          debugPrint(
            '[ParcOto Sync] TENANT API ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId} status=${error.statusCode} code=${error.code} message=${error.message}\n$stackTrace',
          );
          if (error.isPermanent) {
            await queue.markConflict(
              operation.id,
              reason: 'Quota / tenant API rejection (${error.statusCode}, ${error.code}): ${error.message}',
            );
          } else {
            await _markFailedWithBackoff(
              operation,
              errorCode: error.code,
              safeMessage: 'Tenant API request failed (${error.statusCode}).',
            );
          }
          blockedRecords.add(recordKey);
        } on AppwriteException catch (error, stackTrace) {
          debugPrint(
            '[ParcOto Sync] APPWRITE ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId} code=${error.code} type=${error.type} message=${error.message}\n$stackTrace',
          );
          if (error.code == 409) {
            await queue.markConflict(
              operation.id,
              reason:
                  'Appwrite ${error.code} (${error.type ?? 'unknown'}): ${error.message ?? 'Conflit distant'}',
            );
          } else {
            await _markFailedWithBackoff(
              operation,
              errorCode: 'appwrite_${error.code}',
              safeMessage: 'Appwrite request failed (${error.code}).',
            );
          }
          blockedRecords.add(recordKey);
        } catch (error, stackTrace) {
          debugPrint(
            '[ParcOto Sync] ERROR entity=${operation.entity} op=${operation.type.name} id=${operation.entityId}: $error\n$stackTrace',
          );
          await _markFailedWithBackoff(
            operation,
            errorCode: 'unexpected_sync_error',
            safeMessage: 'Unexpected synchronization error.',
          );
          blockedRecords.add(recordKey);
        }
      }

      // Pull only after the outbound queue has been drained. This ordering
      // prevents a remote snapshot from overwriting an acknowledged local edit.
      if (_running && !_leaseLost) {
        for (final entry in pullHandlers.entries) {
          if (!_running || _leaseLost) break;
          try {
            await entry.value();
          } catch (error, stackTrace) {
            debugPrint(
              '[ParcOto Sync] pull failed for ${entry.key}: $error\n$stackTrace',
            );
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('[ParcOto Sync] syncNow crashed: $error\n$stackTrace');
    } finally {
      _leaseTimer?.cancel();
      _leaseTimer = null;
      if (leaseAcquired) {
        try {
          await queue.releaseEngineLease(
            companyId: companyId,
            ownerId: _ownerId,
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[ParcOto Sync] lease release failed: $error\n$stackTrace',
          );
        }
      }
      _syncing = false;
      debugPrint('[ParcOto Sync] syncNow finished');
      final completion = _syncCompletion;
      _syncCompletion = null;
      if (completion != null && !completion.isCompleted) {
        completion.complete();
      }
    }
  }
}
