import '../../../admin_parameters.dart';
import '../../../core/permissions/role.dart';
import '../../../domain/repositories/permission_repository.dart';

/// Legacy compatibility adapter. Tenant roles are resolved from
/// company_memberships during authentication; global Appwrite Teams are never
/// consulted to grant company permissions.
class LegacyAppwritePermissionRepository implements PermissionRepository {
  const LegacyAppwritePermissionRepository();

  @override
  Future<Role> getCurrentRole() async {
    if (isAdminUI) return Role.admin;
    if (isManagerUI) return Role.manager;
    return Role.user;
  }
}
