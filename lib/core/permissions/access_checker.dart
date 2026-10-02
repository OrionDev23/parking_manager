import '../auth/auth_service.dart';

class AccessChecker {
  final AuthService auth;

  const AccessChecker(this.auth);

  bool can(String permission) =>
      auth.session?.hasPermission(permission) ?? false;

  bool canAny(Iterable<String> permissions) =>
      permissions.any(can);

  bool canAll(Iterable<String> permissions) =>
      permissions.every(can);
}
