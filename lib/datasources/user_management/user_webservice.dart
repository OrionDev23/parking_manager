import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';

import '../../providers/client_database.dart';

class UsersWebservice
    extends ParcOtoWebServiceUsers<String, MapEntry<User, List<Membership>?>> {
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

  final Map<String, MapEntry<User, List<Membership>?>> users = {};

  Future<void> loadTeam(User user) async {
    try {
      final memberships = await Users(client).listMemberships(
        userId: user.$id,
      );
      users[user.$id] = MapEntry(user, memberships.memberships);
    } on AppwriteException {
      users[user.$id] = MapEntry(user, null);
    }
  }

  @override
  Future<Map<String, MapEntry<User, List<Membership>?>>> getSearchResult(
      String? searchKey) async {
    await _ready;

    // Never keep users from a previous search/refresh. The old implementation
    // accumulated stale entries because this map was never cleared.
    users.clear();

    final result = await Users(client).list(
      search: searchKey?.trim().isEmpty == true ? null : searchKey?.trim(),
    );

    // Membership loading is independent for each user. Keep it parallel so
    // the table does not become noticeably slower as the number of users grows.
    await Future.wait(result.users.map(loadTeam));

    return Map<String, MapEntry<User, List<Membership>>>.fromEntries(
      users.entries.map(
        (entry) => MapEntry(
          entry.key,
          entry.value,
        ),
      ),
    );
  }

  @override
  int Function(
      MapEntry<String, MapEntry<User, List<Membership>?>> p1,
      MapEntry<String, MapEntry<User, List<Membership>?>> p2)? getComparisonFunction(
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
                    ? d1.value.value!.first.teamName
                    : '')
                .compareTo(
              d2.value.value?.isNotEmpty == true
                  ? d2.value.value!.first.teamName
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
