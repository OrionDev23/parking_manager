import 'package:appwrite/appwrite.dart';

import '../../../core/permissions/permission_catalog.dart';
import '../../../domain/entities/access_team.dart';
import '../../../domain/entities/user_access.dart';
import '../../../domain/repositories/access_control_repository.dart';
import '../../../providers/client_database.dart';

/// Temporary compatibility adapter.
///
/// It maps the existing Appwrite Teams into the new permission model.
/// It will be replaced by the customizable access tables and backend service.
class LegacyAppwriteAccessControlRepository
    implements AccessControlRepository {
  const LegacyAppwriteAccessControlRepository();

  @override
  Future<List<AccessTeam>> getTeams(String companyId) async => const [];

  @override
  Future<AccessTeam?> getTeam(String teamId) async => null;

  @override
  Future<AccessTeam> createTeam(AccessTeam team) {
    throw UnsupportedError('Custom access teams are not migrated yet.');
  }

  @override
  Future<AccessTeam> updateTeam(AccessTeam team) {
    throw UnsupportedError('Custom access teams are not migrated yet.');
  }

  @override
  Future<void> deleteTeam(String teamId) {
    throw UnsupportedError('Custom access teams are not migrated yet.');
  }

  @override
  Future<UserAccess> getUserAccess(String companyId, String userId) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite client is not initialized.');
    }

    final teams = await Teams(client).list();
    final teamNames = teams.teams.map((team) => team.name.toLowerCase()).toSet();

    if (teamNames.contains('admins')) {
      return UserAccess(
        userId: userId,
        companyId: companyId,
        grantedPermissions: PermissionCatalog.all.map((e) => e.id).toSet(),
      );
    }

    if (teamNames.contains('managers')) {
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

    return UserAccess(
      userId: userId,
      companyId: companyId,
    );
  }

  @override
  Future<UserAccess> updateUserAccess(UserAccess access) {
    throw UnsupportedError('Custom user access is not migrated yet.');
  }

  @override
  Future<Set<String>> getEffectivePermissions(
    String companyId,
    String userId,
  ) async {
    final access = await getUserAccess(companyId, userId);
    return access.effectivePermissions(const []);
  }
}
