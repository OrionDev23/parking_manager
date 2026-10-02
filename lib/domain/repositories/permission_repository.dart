import '../entities/../entities/user_profile.dart';
import '../../core/permissions/role.dart';

abstract class PermissionRepository {
  Future<Role> getCurrentRole();
}
