class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? avatar,
  }) {
    return UserProfile(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
