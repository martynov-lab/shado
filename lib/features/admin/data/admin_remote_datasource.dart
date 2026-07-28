import '../../../core/network/api_client.dart';
import '../../auth/domain/entities/auth_user.dart';

/// Страница списка пользователей.
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

/// Админка владельца: `/v1/admin/*`.
abstract interface class AdminRemoteDataSource {
  /// [query] — подстрока email, регистр не важен.
  Future<AdminUserPage> listUsers({String? query, int limit, int offset});

  Future<AuthUser> setRole({required String userId, required UserRole role});
}

class ApiAdminRemoteDataSource implements AdminRemoteDataSource {
  const ApiAdminRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<AdminUserPage> listUsers({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final json = await _client.get(
      '/v1/admin/users',
      query: {
        'q': ?(query == null || query.isEmpty ? null : query),
        'limit': limit,
        'offset': offset,
      },
    );
    return AdminUserPage.fromJson(json);
  }

  @override
  Future<AuthUser> setRole({
    required String userId,
    required UserRole role,
  }) async {
    final response = await _client.patch(
      '/v1/admin/users/$userId/role',
      data: {'role': role.name},
    );
    return AuthUser.fromJson(response.data!);
  }
}
