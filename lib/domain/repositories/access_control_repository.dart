import '../entities/access_team.dart';
import '../entities/user_access.dart';

abstract class AccessControlRepository {
  Future<List<AccessTeam>> getTeams(String companyId);
  Future<AccessTeam?> getTeam(String teamId);
  Future<AccessTeam> createTeam(AccessTeam team);
  Future<AccessTeam> updateTeam(AccessTeam team);
  Future<void> deleteTeam(String teamId);

  Future<UserAccess> getUserAccess(String companyId, String userId);
  Future<UserAccess> updateUserAccess(UserAccess access);

  Future<Set<String>> getEffectivePermissions(String companyId, String userId);
}
