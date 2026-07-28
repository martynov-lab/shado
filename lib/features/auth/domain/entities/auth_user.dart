/// Роль пользователя. Задаётся сервером (владелец — по почте из его
/// конфигурации), клиент её только читает.
enum UserRole {
  user,
  owner;

  static UserRole parse(String? raw) =>
      raw == 'owner' ? UserRole.owner : UserRole.user;

  bool get isOwner => this == UserRole.owner;
}

/// Вошедший пользователь.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    role: UserRole.parse(json['role'] as String?),
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc(),
  );

  final String id;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  bool get isOwner => role.isOwner;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.email == email &&
          other.role == role;

  @override
  int get hashCode => Object.hash(id, email, role);

  @override
  String toString() => 'AuthUser($email, ${role.name})';
}
