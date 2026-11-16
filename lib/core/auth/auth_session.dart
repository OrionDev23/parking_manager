import '../licensing/license.dart';
import '../tenancy/company_context.dart';

class AuthSession {
  final String userId;
  final String email;
  final String? displayName;
  final CompanyContext company;
  final Set<String> permissions;
  final License? license;
  final bool isOfflineSession;
  final bool isPlatformSuperAdmin;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.company,
    this.displayName,
    this.permissions = const {},
    this.license,
    this.isOfflineSession = false,
    this.isPlatformSuperAdmin = false,
  });

  bool hasPermission(String permission) =>
      permissions.contains(permission) || permissions.contains('*');
}
