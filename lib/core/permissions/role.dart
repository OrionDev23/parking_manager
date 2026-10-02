class Role {
  final String id;
  final String name;
  final Set<String> permissions;

  const Role({
    required this.id,
    required this.name,
    this.permissions = const {},
  });

  bool allows(String permission) => permissions.contains(permission);

  static const admin = Role(
    id: 'admin',
    name: 'Admin',
    permissions: {'*'},
  );

  static const manager = Role(
    id: 'manager',
    name: 'Manager',
  );

  static const user = Role(
    id: 'user',
    name: 'User',
  );
}
