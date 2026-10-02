import '../../../core/network/api_client.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../domain/entities/admin_user_page.dart';

/// Owner admin API: `/v1/admin/*`.
abstract interface class AdminRemoteDataSource {
  /// [query] is an email substring, case-insensitive.
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
      data: {'role': role.wire},
    );
    return AuthUser.fromJson(response.data!);
  }
}
