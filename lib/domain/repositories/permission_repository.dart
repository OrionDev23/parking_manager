import '../../core/permissions/role.dart';

abstract class PermissionRepository {
  Future<Role> getCurrentRole();
}
