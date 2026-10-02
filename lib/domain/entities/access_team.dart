class AccessTeam {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final Set<String> permissions;
  final bool isSystem;

  const AccessTeam({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.permissions = const {},
    this.isSystem = false,
  });

  AccessTeam copyWith({
    String? name,
    String? description,
    Set<String>? permissions,
  }) {
    return AccessTeam(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isSystem: isSystem,
    );
  }
}
