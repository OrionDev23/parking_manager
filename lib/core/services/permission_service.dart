import '../../core/permissions/role.dart';
import '../../domain/repositories/permission_repository.dart';

class PermissionService {
  final PermissionRepository repository;

  const PermissionService({required this.repository});

  Future<Role> getCurrentRole() => repository.getCurrentRole();
}
