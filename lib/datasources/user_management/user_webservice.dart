import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';

import '../../providers/client_database.dart';

class UsersWebservice
    extends ParcOtoWebServiceUsers<String, MapEntry<User, List<String>?>> {
  final Client client = Client();
  late final Future<void> _ready;

  UsersWebservice(super.data) {
    _ready = _initializeClient();
  }

  Future<void> _initializeClient() async {
    // The Users API is a server-side API, so this legacy screen still
    // requires the existing server key. Do not start the list request until
    // the key and project are actually ready.
    if (!DatabaseGetter.secretKeySet) {
      await DatabaseGetter().setSecretKey();
    }

    const timeout = Duration(seconds: 10);
    final startedAt = DateTime.now();
    while (!DatabaseGetter.secretKeySet) {
      if (DateTime.now().difference(startedAt) >= timeout) {
        throw StateError('Le service utilisateurs Appwrite n’est pas prêt.');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final resolvedProject = project;
    final resolvedKey = secretKey;
    if (resolvedProject == null ||
        resolvedProject.isEmpty ||
        resolvedKey == null ||
        resolvedKey.isEmpty) {
      throw StateError('Configuration Appwrite utilisateurs introuvable.');
    }

    client
      ..setProject(resolvedProject)
      ..setKey(resolvedKey)
      ..setEndpoint(endpoint);
  }

  final Map<String, MapEntry<User, List<String>?>> users = {};

  Future<void> loadTeams(
    User user,
    Map<String, String> teamNames,
    Map<String, List<String>> accessByUser,
  ) async {
    final teamNamesForUser = accessByUser[user.$id]
            ?.map((id) => teamNames[id])
            .whereType<String>()
            .toList() ??
        <String>[];

    users[user.$id] = MapEntry(
      user,
      teamNamesForUser,
    );
  }

  @override
  Future<Map<String, MapEntry<User, List<String>?>>> getSearchResult(
      String? searchKey) async {
    await _ready;

    // Never keep users from a previous search/refresh. The old implementation
    // accumulated stale entries because this map was never cleared.
    users.clear();

    final result = await Users(client).list(
      search: searchKey?.trim().isEmpty == true ? null : searchKey?.trim(),
    );

    // Read ParcOto's own access model in two queries instead of doing one
    // Appwrite Teams membership request per user. This is both faster and,
    // more importantly, makes the UI display the new customizable teams.
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('La base Appwrite n’est pas initialisée.');
    }

    final accessTeams = await database.listRows(
      databaseId: databaseId,
      tableId: 'access_teams',
      queries: [Query.limit(500)],
    );
    final accessUsers = await database.listRows(
      databaseId: databaseId,
      tableId: 'access_users',
      queries: [Query.limit(500)],
    );

    final teamNames = <String, String>{
      for (final row in accessTeams.rows)
        row.$id: row.data['name']?.toString() ?? row.$id,
    };
    final accessByUser = <String, List<String>>{};
    for (final row in accessUsers.rows) {
      final userId = row.data['userId']?.toString() ?? row.$id;
      final ids = row.data['teamIds'];
      if (ids is List) {
        accessByUser[userId] = ids.map((id) => id.toString()).toList();
      }
    }

    await Future.wait(
      result.users.map(
        (user) => loadTeams(user, teamNames, accessByUser),
      ),
    );

    return users;
  }

  @override
  int Function(
      MapEntry<String, MapEntry<User, List<String>?>> p1,
      MapEntry<String, MapEntry<User, List<String>?>> p2)? getComparisonFunction(
      int column, bool ascending) {
    final coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return (d1, d2) =>
            coef * d1.value.key.name.compareTo(d2.value.key.name);
      case 1:
        return (d1, d2) =>
            coef * d1.value.key.email.compareTo(d2.value.key.email);
      case 2:
        return (d1, d2) => coef * d1.value.key.$id.compareTo(d2.value.key.$id);
      case 3:
        return (d1, d2) =>
            coef *
            (d1.value.value?.isNotEmpty == true
                    ? d1.value.value!.first
                    : '')
                .compareTo(
              d2.value.value?.isNotEmpty == true
                  ? d2.value.value!.first
                  : '',
            );
      case 4:
        return (d1, d2) =>
            coef * d1.value.key.$createdAt.compareTo(d2.value.key.$createdAt);
      default:
        return (d1, d2) =>
            coef * d1.value.key.$createdAt.compareTo(d2.value.key.$createdAt);
    }
  }
}
