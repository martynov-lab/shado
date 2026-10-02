import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/admin_providers.dart';
import 'package:shado/di/auth_providers.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/entities/admin_user_page.dart';
import '../../domain/repositories/admin_users_repository.dart';

/// Data and actions of the users screen.
class AdminUsersModel extends ElementaryModel {
  AdminUsersModel(ProviderContainer container)
    : _repository = container.read(adminUsersRepositoryProvider),
      _auth = container.read(authServiceProvider);

  static const int pageSize = 50;

  final AdminUsersRepository _repository;
  final AuthService _auth;

  late final StreamValueNotifier<String?> _currentUserId = StreamValueNotifier(
    _auth.session.user?.id,
    _auth.changes.map((session) => session.user?.id),
  );

  ValueListenable<String?> get currentUserId => _currentUserId;

  Future<AdminUserPage> listUsers({required String query, int offset = 0}) =>
      _repository.listUsers(query: query, limit: pageSize, offset: offset);

  Future<AuthUser> setRole(String userId, UserRole role) =>
      _repository.setRole(userId: userId, role: role);

  /// Re-reads the signed-in user: the role may have been changed on another
  /// device.
  Future<void> reloadCurrentUser() => _auth.reloadUser();

  @override
  void dispose() {
    _currentUserId.dispose();
    super.dispose();
  }
}
