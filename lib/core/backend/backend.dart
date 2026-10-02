import 'backend_config.dart';

abstract class Backend {
  BackendConfig get config;
  Future<void> initialize();
  Future<void> dispose();
}
