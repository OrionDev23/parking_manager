import 'package:appwrite/appwrite.dart';

import 'backend.dart';
import 'backend_config.dart';

class AppwriteBackend implements Backend {
  @override
  final BackendConfig config;

  late final Client client;
  late final Account account;
  late final TablesDB database;
  late final Storage storage;

  AppwriteBackend(this.config);

  @override
  Future<void> initialize() async {
    final endpoint = config.endpoint;
    final projectId = config.projectId;
    if (endpoint == null || endpoint.isEmpty) {
      throw StateError('Appwrite endpoint is required.');
    }
    if (projectId == null || projectId.isEmpty) {
      throw StateError('Appwrite project id is required.');
    }

    client = Client()
      ..setEndpoint(endpoint)
      ..setProject(projectId);
    account = Account(client);
    database = TablesDB(client);
    storage = Storage(client);
  }

  @override
  Future<void> dispose() async {}
}
