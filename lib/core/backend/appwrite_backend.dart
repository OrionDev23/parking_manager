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

  final Client? _providedClient;

  AppwriteBackend(this.config, {Client? client})
    : _providedClient = client;

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

    // Reuse the authenticated client when the application already has a
    // signed-in Appwrite session. Creating a second client here silently
    // drops the session cookie and makes tenant-scoped reads fail.
    client = _providedClient ??
        (Client()
          ..setEndpoint(endpoint)
          ..setProject(projectId));
    account = Account(client);
    database = TablesDB(client);
    storage = Storage(client);
  }

  @override
  Future<void> dispose() async {}
}
