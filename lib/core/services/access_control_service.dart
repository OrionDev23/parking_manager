import '../../domain/entities/access_team.dart';
import '../../domain/entities/user_access.dart';
import '../../domain/repositories/access_control_repository.dart';

class AccessControlService {
  final AccessControlRepository repository;

  const AccessControlService({required this.repository});

  Future<List<AccessTeam>> getTeams(String companyId) =>
      repository.getTeams(companyId);

  Future<AccessTeam> createTeam(AccessTeam team) =>
      repository.createTeam(team);

  Future<AccessTeam> updateTeam(AccessTeam team) =>
      repository.updateTeam(team);

  Future<void> deleteTeam(String teamId) =>
      repository.deleteTeam(teamId);

  Future<UserAccess> getUserAccess(String companyId, String userId) =>
      repository.getUserAccess(companyId, userId);

  Future<UserAccess> updateUserAccess(UserAccess access) =>
      repository.updateUserAccess(access);

  Future<Set<String>> getEffectivePermissions(
    String companyId,
    String userId,
  ) =>
      repository.getEffectivePermissions(companyId, userId);
}
