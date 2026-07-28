import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../data/admin_remote_datasource.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => ApiAdminRemoteDataSource(ref.watch(apiClientProvider)),
);

class AdminUsersState {
  const AdminUsersState({
    this.users = const [],
    this.total = 0,
    this.query = '',
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<AuthUser> users;
  final int total;
  final String query;
  final bool hasMore;
  final bool isLoadingMore;

  AdminUsersState copyWith({
    List<AuthUser>? users,
    int? total,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Список пользователей и смена ролей. Доступен только владельцу — и это
/// проверяет сервер, а не экран.
class AdminUsersController extends AsyncNotifier<AdminUsersState> {
  static const int _pageSize = 50;

  /// Поиск не дёргает сервер на каждую букву.
  static const Duration _searchDebounce = Duration(milliseconds: 350);

  Timer? _debounce;
  String _query = '';

  @override
  Future<AdminUsersState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return _load(_query);
  }

  Future<AdminUsersState> _load(String query) async {
    final page = await ref
        .read(adminRemoteDataSourceProvider)
        .listUsers(query: query, limit: _pageSize);
    return AdminUsersState(
      users: page.users,
      total: page.total,
      query: query,
      hasMore: page.hasMore,
    );
  }

  void search(String query) {
    _query = query.trim();
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _load(_query));
    });
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref
          .read(adminRemoteDataSourceProvider)
          .listUsers(
            query: current.query,
            limit: _pageSize,
            offset: current.users.length,
          );
      state = AsyncValue.data(
        current.copyWith(
          users: [...current.users, ...page.users],
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Меняет роль и заменяет пользователя в списке ответом сервера.
  Future<void> setRole(String userId, UserRole role) async {
    final current = state.value;
    if (current == null) return;
    final updated = await ref
        .read(adminRemoteDataSourceProvider)
        .setRole(userId: userId, role: role);
    state = AsyncValue.data(
      current.copyWith(
        users: [
          for (final user in current.users)
            if (user.id == userId) updated else user,
        ],
      ),
    );
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminUsersController, AdminUsersState>(
      AdminUsersController.new,
    );
