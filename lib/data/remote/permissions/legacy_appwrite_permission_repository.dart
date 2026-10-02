import 'package:appwrite/appwrite.dart' hide Role;

import '../../../admin_parameters.dart';
import '../../../providers/client_database.dart';
import '../../../core/permissions/role.dart';
import '../../../domain/repositories/permission_repository.dart';

class LegacyAppwritePermissionRepository implements PermissionRepository {
  const LegacyAppwritePermissionRepository();

  @override
  Future<Role> getCurrentRole() async {
    if (isAdminUI) return Role.admin;
    if (isManagerUI) return Role.manager;

    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite client is not initialized.');
    }

    final teams = await Teams(client).list();

    final isAdmin =
        teams.teams.any((team) => team.name.toLowerCase() == 'admins');
    if (isAdmin) return Role.admin;

    final isManager =
        teams.teams.any((team) => team.name.toLowerCase() == 'managers');
    if (isManager) return Role.manager;

    return Role.user;
  }
}
