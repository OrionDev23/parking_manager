import 'backend_type.dart';

class BackendConfig {
  final BackendType type;
  final String? endpoint;
  final String? projectId;

  const BackendConfig({required this.type, this.endpoint, this.projectId});

  const BackendConfig.local() : this(type: BackendType.local);
}
