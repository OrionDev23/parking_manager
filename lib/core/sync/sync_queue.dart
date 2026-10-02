import 'sync_operation.dart';

abstract class SyncQueue {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> pending({int limit = 50});
  Future<void> markCompleted(String operationId);
  Future<void> markFailed(String operationId);
  Future<void> markConflict(String operationId);
}
