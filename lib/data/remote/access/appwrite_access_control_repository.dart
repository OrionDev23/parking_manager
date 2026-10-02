import 'package:appwrite/appwrite.dart';

import '../../../core/permissions/permission_catalog.dart';
import '../../../domain/entities/access_team.dart';
import '../../../domain/entities/user_access.dart';
import '../../../domain/repositories/access_control_repository.dart';
import '../../../providers/client_database.dart';

class AppwriteAccessControlRepository implements AccessControlRepository {
  const AppwriteAccessControlRepository();

  TablesDB get _database {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database is not initialized.');
    }
    return database;
  }

  @override
  Future<List<AccessTeam>> getTeams(String companyId) async {
    final result = await _database.listRows(
      databaseId: databaseId,
      tableId: 'access_teams',
      queries: [Query.equal('companyId', companyId), Query.limit(500)],
    );
    return result.rows
        .map((row) => _teamFromMap(Map<String, dynamic>.from(row.data), row.$id))
        .toList(growable: false);
  }

  @override
  Future<AccessTeam?> getTeam(String teamId) async {
    try {
      final row = await _database.getRow(
        databaseId: databaseId,
        tableId: 'access_teams',
        rowId: teamId,
      );
      return _teamFromMap(Map<String, dynamic>.from(row.data), row.$id);
    } on AppwriteException catch (error) {
      if (error.code == 404) return null;
      rethrow;
    }
  }

  @override
  Future<AccessTeam> createTeam(AccessTeam team) async {
    _checkTeam(team);
    final id = team.id.isEmpty ? ID.unique() : team.id;
    await _database.createRow(
      databaseId: databaseId,
      tableId: 'access_teams',
      rowId: id,
      data: _teamToMap(team),
    );
    return AccessTeam(
      id: id,
      companyId: team.companyId,
      name: team.name,
      description: team.description,
      permissions: team.permissions,
      isSystem: team.isSystem,
    );
  }

  @override
  Future<AccessTeam> updateTeam(AccessTeam team) async {
    _checkTeam(team);
    await _database.updateRow(
      databaseId: databaseId,
      tableId: 'access_teams',
      rowId: team.id,
      data: _teamToMap(team),
    );
    return team;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _database.deleteRow(
      databaseId: databaseId,
      tableId: 'access_teams',
      rowId: teamId,
    );
  }

  @override
  Future<UserAccess> getUserAccess(String companyId, String userId) async {
    try {
      final row = await _database.getRow(
        databaseId: databaseId,
        tableId: 'access_users',
        rowId: userId,
      );
      final access = _userAccessFromMap(
        Map<String, dynamic>.from(row.data),
        row.$id,
      );
      if (access.companyId != companyId) {
        throw StateError('User access company does not match.');
      }
      return access;
    } on AppwriteException catch (error) {
      if (error.code != 404) rethrow;

      // Transitional compatibility: existing installations still use
      // Appwrite Teams. A user without an access_users row keeps the
      // legacy access until an explicit Parcoto access profile is created.
      final client = DatabaseGetter.client;
      if (client != null) {
        final teams = await Teams(client).list();
        final names = teams.teams.map((team) => team.name.toLowerCase()).toSet();

        if (names.contains('admins')) {
          return UserAccess(
            userId: userId,
            companyId: companyId,
            grantedPermissions: PermissionCatalog.all.map((e) => e.id).toSet(),
          );
        }

        if (names.contains('managers')) {
          return UserAccess(
            userId: userId,
            companyId: companyId,
            grantedPermissions: {
              for (final permission in PermissionCatalog.all)
                if (permission.module != 'users' &&
                    permission.module != 'teams' &&
                    permission.module != 'permissions' &&
                    permission.module != 'backup')
                  permission.id,
            },
          );
        }
      }

      return UserAccess(userId: userId, companyId: companyId);
    }
  }

  @override
  Future<UserAccess> updateUserAccess(UserAccess access) async {
    final data = _userAccessToMap(access);
    try {
      await _database.updateRow(
        databaseId: databaseId,
        tableId: 'access_users',
        rowId: access.userId,
        data: data,
      );
    } on AppwriteException catch (error) {
      if (error.code != 404) rethrow;
      await _database.createRow(
        databaseId: databaseId,
        tableId: 'access_users',
        rowId: access.userId,
        data: data,
      );
    }
    return access;
  }

  @override
  Future<Set<String>> getEffectivePermissions(
    String companyId,
    String userId,
  ) async {
    final access = await getUserAccess(companyId, userId);
    final teams = <Set<String>>[];
    for (final teamId in access.teamIds) {
      final team = await getTeam(teamId);
      if (team != null && team.companyId == companyId) {
        teams.add(team.permissions);
      }
    }
    return access.effectivePermissions(teams);
  }

  AccessTeam _teamFromMap(Map<String, dynamic> data, String id) {
    return AccessTeam(
      id: id,
      companyId: data['companyId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      permissions: _stringSet(data['permissions']),
      isSystem: data['isSystem'] == true,
    );
  }

  Map<String, dynamic> _teamToMap(AccessTeam team) => {
        'companyId': team.companyId,
        'name': team.name,
        'description': team.description,
        'permissions': team.permissions.toList(),
        'isSystem': team.isSystem,
      };

  UserAccess _userAccessFromMap(Map<String, dynamic> data, String id) {
    return UserAccess(
      userId: data['userId']?.toString() ?? id,
      companyId: data['companyId']?.toString() ?? '',
      teamIds: _stringSet(data['teamIds']),
      grantedPermissions: _stringSet(data['grantedPermissions']),
      deniedPermissions: _stringSet(data['deniedPermissions']),
    );
  }

  Map<String, dynamic> _userAccessToMap(UserAccess access) => {
        'companyId': access.companyId,
        'userId': access.userId,
        'teamIds': access.teamIds.toList(),
        'grantedPermissions': access.grantedPermissions.toList(),
        'deniedPermissions': access.deniedPermissions.toList(),
      };

  Set<String> _stringSet(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toSet();
    }
    return <String>{};
  }

  void _checkTeam(AccessTeam team) {
    if (team.companyId.isEmpty) {
      throw StateError('An access team must belong to a company.');
    }
    final unknown = team.permissions
        .where((id) => PermissionCatalog.find(id) == null)
        .toList();
    if (unknown.isNotEmpty) {
      throw ArgumentError('Unknown permissions: ${unknown.join(', ')}');
    }
  }
}
