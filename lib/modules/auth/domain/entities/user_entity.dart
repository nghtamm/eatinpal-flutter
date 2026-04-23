class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? avatarURL;
  final bool emailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarURL,
    required this.emailVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
