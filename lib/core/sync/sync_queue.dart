import 'sync_operation.dart';

abstract class SyncQueue {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> pending({int limit = 50, String? companyId});
  Future<void> markProcessing(String operationId);
  Future<void> recoverInterrupted({String? companyId});
  Future<void> markCompleted(String operationId);
  Future<void> markFailed(String operationId);
  Future<void> markConflict(String operationId, {required String reason});
  Future<List<SyncOperation>> conflicts({String? companyId, int limit = 100});
  Future<void> retryConflict(String operationId);

  /// Atomically acquires the company-wide sync lease if it is free or expired.
  Future<bool> acquireEngineLease({
    required String companyId,
    required String ownerId,
    required DateTime now,
    required Duration leaseDuration,
  });

  Future<bool> renewEngineLease({
    required String companyId,
    required String ownerId,
    required DateTime now,
    required Duration leaseDuration,
  });

  Future<void> releaseEngineLease({
    required String companyId,
    required String ownerId,
  });
}
