/// Роль пользователя. Задаётся сервером (владелец — по почте из его
/// конфигурации), клиент её только читает.
enum UserRole {
  user('user'),
  userPro('user-pro'),
  admin('admin'),
  owner('owner');

  const UserRole(this.wire);

  /// Строка роли в протоколе сервера (§6). Уезжает обратно в админке при
  /// смене роли пользователя.
  final String wire;

  /// Незнакомую роль не считаем «всё разрешено»: сервер мог добавить более
  /// привилегированную роль, а старый клиент безопаснее откатить к `user`.
  static UserRole parse(String? raw) {
    for (final role in UserRole.values) {
      if (role.wire == raw) return role;
    }
    return UserRole.user;
  }

  bool get isOwner => this == UserRole.owner;
  bool get isAdmin => this == UserRole.admin;
  bool get isPro => this == UserRole.userPro;

  /// Кто вправе создавать и править уроки: pro (свои приватные), админ и
  /// владелец.
  bool get canAuthor =>
      this == UserRole.userPro ||
      this == UserRole.admin ||
      this == UserRole.owner;

  /// Кто видит вкладку «Управление» (пользователи, порог пройденности).
  bool get canManage => this == UserRole.owner;
}

/// Вошедший пользователь.
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

  /// Профиль (§6). `null` — сервер поля не прислал (старый ответ или
  /// незаполненное значение).
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

  /// Пустую строку из JSON держим за отсутствие значения.
  static String? _nonEmpty(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
