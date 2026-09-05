/// User role; assigned by the server, the client only reads it.
enum UserRole {
  user('user'),
  userPro('user-pro'),
  admin('admin'),
  owner('owner');

  const UserRole(this.wire);

  /// Role string in the server protocol.
  final String wire;

  /// Parses a role; an unknown one falls back to `user`.
  static UserRole parse(String? raw) {
    for (final role in UserRole.values) {
      if (role.wire == raw) return role;
    }
    return UserRole.user;
  }

  bool get isOwner => this == UserRole.owner;
  bool get isAdmin => this == UserRole.admin;
  bool get isPro => this == UserRole.userPro;

  /// Whether the role may create and edit lessons.
  bool get canAuthor =>
      this == UserRole.userPro ||
      this == UserRole.admin ||
      this == UserRole.owner;

  /// Whether the role sees the management tab.
  bool get canManage => this == UserRole.owner;
}

/// Signed-in user.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.name,
    this.studiedLanguage,
    this.dailyGoalMinutes,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    role: UserRole.parse(json['role'] as String?),
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc(),
    name: _nonEmpty(json['name']),
    studiedLanguage: _nonEmpty(json['studied_language']),
    dailyGoalMinutes: (json['daily_goal_minutes'] as num?)?.toInt(),
  );

  final String id;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  /// Profile fields; `null` when the server did not send them.
  final String? name;
  final String? studiedLanguage;
  final int? dailyGoalMinutes;

  bool get isOwner => role.isOwner;

  AuthUser copyWith({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) => AuthUser(
    id: id,
    email: email,
    role: role,
    createdAt: createdAt,
    name: name ?? this.name,
    studiedLanguage: studiedLanguage ?? this.studiedLanguage,
    dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.email == email &&
          other.role == role &&
          other.name == name &&
          other.studiedLanguage == studiedLanguage &&
          other.dailyGoalMinutes == dailyGoalMinutes;

  @override
  int get hashCode =>
      Object.hash(id, email, role, name, studiedLanguage, dailyGoalMinutes);

  @override
  String toString() => 'AuthUser($email, ${role.name})';

  /// An empty JSON string means the value is absent.
  static String? _nonEmpty(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
