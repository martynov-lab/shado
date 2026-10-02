import '../../../auth/domain/entities/auth_user.dart';

/// A page of the user list.
class AdminUserPage {
  const AdminUserPage({
    required this.users,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory AdminUserPage.fromJson(Map<String, dynamic> json) => AdminUserPage(
    users: [
      for (final user in (json['users'] as List<dynamic>? ?? const []))
        AuthUser.fromJson(user as Map<String, dynamic>),
    ],
    total: (json['total'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    offset: (json['offset'] as num?)?.toInt() ?? 0,
  );

  final List<AuthUser> users;
  final int total;
  final int limit;
  final int offset;

  bool get hasMore => offset + users.length < total;
}
