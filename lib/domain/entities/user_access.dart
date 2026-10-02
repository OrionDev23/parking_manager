class UserAccess {
  final String userId;
  final String companyId;
  final Set<String> teamIds;
  final Set<String> grantedPermissions;
  final Set<String> deniedPermissions;

  const UserAccess({
    required this.userId,
    required this.companyId,
    this.teamIds = const {},
    this.grantedPermissions = const {},
    this.deniedPermissions = const {},
  });

  Set<String> effectivePermissions(Iterable<Set<String>> teamPermissions) {
    final effective = <String>{};
    for (final permissions in teamPermissions) {
      effective.addAll(permissions);
    }
    effective.addAll(grantedPermissions);
    effective.removeAll(deniedPermissions);
    return effective;
  }
}
