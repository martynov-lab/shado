import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/admin_user_page.dart';
import '../../domain/repositories/admin_users_repository.dart';
import '../admin_remote_datasource.dart';

class AdminUsersRepositoryImpl implements AdminUsersRepository {
  const AdminUsersRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<AdminUserPage> listUsers({
    String? query,
    int limit = 50,
    int offset = 0,
  }) => _remote.listUsers(query: query, limit: limit, offset: offset);

  @override
  Future<AuthUser> setRole({required String userId, required UserRole role}) =>
      _remote.setRole(userId: userId, role: role);
}
