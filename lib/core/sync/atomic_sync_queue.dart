import 'sync_operation.dart';

/// Persists an outbox operation and its local entity mutation in one durable
/// transaction. Implemented by the native SQLite queue only.
abstract interface class AtomicSyncQueue {
  Future<void> enqueueWithLocalMutation(
    SyncOperation operation, {
    required void Function() localMutation,
  });
}
