class Permission {
  final String id;
  final String label;
  final String module;
  final String action;
  final String? description;

  const Permission({
    required this.id,
    required this.label,
    required this.module,
    required this.action,
    this.description,
  });
}
