import '../licensing/license.dart';
import '../permissions/role.dart';
import '../tenancy/company_context.dart';

class AuthSession {
  final String userId;
  final String email;
  final String? displayName;
  final CompanyContext company;
  final Role role;
  final Set<String> permissions;
  final License? license;
  final bool isOfflineSession;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.company,
    required this.role,
    this.displayName,
    this.permissions = const {},
    this.license,
    this.isOfflineSession = false,
  });

  bool hasPermission(String permission) =>
      permissions.contains(permission) || permissions.contains('*') || role.allows(permission) || role.permissions.contains('*');
}
