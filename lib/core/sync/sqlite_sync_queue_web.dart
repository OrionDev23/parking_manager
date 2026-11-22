import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'atomic_sync_queue.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

/// In-memory queue for Web only. It never persists work while offline.
class SqliteSyncQueue implements SyncQueue, AtomicSyncQueue {
  final List<SyncOperation> _operations = [];
  final Map<String, String> _leases = {};
  final Map<String, DateTime> _retryAt = {};

  SqliteSyncQueue([dynamic _]);

  SyncOperation _replace(
    SyncOperation item, {
    SyncOperationStatus? status,
    int? attempts,
    String? conflictReason,
    DateTime? conflictedAt,
    bool clearConflict = false,
  }) => SyncOperation(
    id: item.id,
    idempotencyKey: item.idempotencyKey,
    payloadVersion: item.payloadVersion,
    companyId: item.companyId,
    deviceId: item.deviceId,
    entity: item.entity,
    entityId: item.entityId,
    type: item.type,
    payload: item.payload,
    createdAt: item.createdAt,
    status: status ?? item.status,
    attempts: attempts ?? item.attempts,
    conflictReason: clearConflict ? null : conflictReason ?? item.conflictReason,
    conflictedAt: clearConflict ? null : conflictedAt ?? item.conflictedAt,
  );

  @override
  Future<void> enqueue(SyncOperation operation) async {
    if (!await InternetConnection().hasInternetAccess) {
      throw StateError(
        'Connexion Internet requise : les modifications sont désactivées hors ligne sur ParcOto Web.',
      );
    }
    final index = _operations.indexWhere((item) =>
        item.companyId == operation.companyId &&
        item.entity == operation.entity &&
        item.entityId == operation.entityId &&
        item.status == SyncOperationStatus.pending);
    if (index >= 0) _operations.removeAt(index);
    _operations.add(operation);
  }

  @override
  Future<void> enqueueWithLocalMutation(
    SyncOperation operation, {
    required void Function() localMutation,
  }) async {
    // The Web vehicle repository is online-only and does not use the local
    // outbox. Fail closed if this native-only transaction API is ever called.
    throw UnsupportedError(
      'Atomic SQLite mutations are not available on Parcoto Web.',
    );
  }

  @override
  Future<List<SyncOperation>> pending({int limit = 50, String? companyId}) async =>
      _operations.where((item) =>
        item.status == SyncOperationStatus.pending ||
        item.status == SyncOperationStatus.conflict ||
        (item.status == SyncOperationStatus.failed &&
          (_retryAt[item.id] == null ||
            !_retryAt[item.id]!.isAfter(DateTime.now().toUtc()))))
      .where((item) => companyId == null || item.companyId == companyId)
      .take(limit).toList(growable: false);

  @override
  Future<void> markProcessing(String id) async {
    final i = _operations.indexWhere((item) => item.id == id);
    if (i >= 0) _operations[i] = _replace(_operations[i], status: SyncOperationStatus.processing);
  }
  @override
  Future<void> recoverInterrupted({String? companyId}) async {
    for (var i = 0; i < _operations.length; i++) {
      final item = _operations[i];
      if (item.status == SyncOperationStatus.processing &&
          (companyId == null || item.companyId == companyId)) {
        _operations[i] = _replace(item, status: SyncOperationStatus.pending);
      }
    }
  }
  @override
  Future<void> markCompleted(String id) async {
    _retryAt.remove(id);
    _operations.removeWhere((item) => item.id == id);
  }
  @override
  Future<void> markFailed(
    String id, {
    required String errorCode,
    required String errorMessage,
    required DateTime nextAttemptAt,
  }) async {
    final i = _operations.indexWhere((item) => item.id == id);
    if (i >= 0) {
      final item = _operations[i];
      _operations[i] = _replace(
        item,
        status: SyncOperationStatus.failed,
        attempts: item.attempts + 1,
      );
      _retryAt[id] = nextAttemptAt.toUtc();
    }
  }
  @override
  Future<void> markConflict(String id, {required String reason}) async {
    final i = _operations.indexWhere((item) => item.id == id);
    if (i >= 0) {
      _operations[i] = _replace(
        _operations[i],
        status: SyncOperationStatus.conflict,
        conflictReason: reason,
        conflictedAt: DateTime.now().toUtc(),
      );
    }
  }
  @override
  Future<bool> hasUnresolvedMutation({
    required String companyId,
    required String entity,
    required String entityId,
  }) async => _operations.any((item) =>
      item.companyId == companyId && item.entity == entity &&
      item.entityId == entityId &&
      item.status != SyncOperationStatus.completed);
  @override
  Future<bool> acquireEngineLease({
    required String companyId,
    required String ownerId,
    required DateTime now,
    required Duration leaseDuration,
  }) async {
    final current = _leases[companyId];
    if (current != null && current != ownerId) return false;
    _leases[companyId] = ownerId;
    return true;
  }
  @override
  Future<bool> renewEngineLease({
    required String companyId,
    required String ownerId,
    required DateTime now,
    required Duration leaseDuration,
  }) async => _leases[companyId] == ownerId;
  @override
  Future<void> releaseEngineLease({
    required String companyId,
    required String ownerId,
  }) async {
    if (_leases[companyId] == ownerId) _leases.remove(companyId);
  }
  @override
  Future<List<SyncOperation>> conflicts({String? companyId, int limit = 100}) async =>
      _operations.where((item) =>
        item.status == SyncOperationStatus.conflict &&
        (companyId == null || item.companyId == companyId))
      .take(limit).toList(growable: false);
  @override
  Future<void> retryConflict(String id) async {
    _retryAt.remove(id);
    final i = _operations.indexWhere((item) => item.id == id);
    if (i >= 0) {
      _operations[i] = _replace(
        _operations[i],
        status: SyncOperationStatus.pending,
        clearConflict: true,
      );
    }
  }
}
