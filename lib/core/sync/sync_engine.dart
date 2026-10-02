abstract class SyncEngine {
  bool get isRunning;
  Future<void> start();
  Future<void> stop();
  Future<void> syncNow();
}
