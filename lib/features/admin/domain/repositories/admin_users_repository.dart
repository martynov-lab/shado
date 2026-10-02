import '../../../auth/domain/entities/auth_user.dart';
import '../entities/admin_user_page.dart';

/// Users and their roles, available to the owner only.
abstract interface class AdminUsersRepository {
  /// [query] is a part of the email, case-insensitive.
  Future<AdminUserPage> listUsers({String? query, int limit, int offset});

  /// Returns the user as the server saved it.
  Future<AuthUser> setRole({required String userId, required UserRole role});
}
