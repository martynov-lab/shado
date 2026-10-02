import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import 'admin_users_model.dart';
import 'admin_users_page.dart';
import 'admin_users_state.dart';

AdminUsersWidgetModel adminUsersWidgetModelFactory(BuildContext context) =>
    AdminUsersWidgetModel(
      AdminUsersModel(ProviderScope.containerOf(context, listen: false)),
    );

class AdminUsersWidgetModel
    extends WidgetModel<AdminUsersPage, AdminUsersModel> {
  AdminUsersWidgetModel(super.model);

  static const Duration _searchDebounce = Duration(milliseconds: 350);
  static const double _loadMoreOffset = 320;

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<AsyncState<AdminUsersState>> _users = ValueNotifier(
    const AsyncPending(),
  );
  Timer? _debounce;
  String _query = '';

  ValueListenable<AsyncState<AdminUsersState>> get users => _users;
  ValueListenable<String?> get currentUserId => model.currentUserId;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    scrollController.addListener(_onScroll);
    unawaited(model.reloadCurrentUser());
    unawaited(_reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    scrollController.dispose();
    searchController.dispose();
    _users.dispose();
    super.dispose();
  }

  void search(String query) {
    _query = query.trim();
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      _users.value = const AsyncPending();
      unawaited(_reload());
    });
  }

  Future<void> refresh() => _reload();

  Future<void> loadMore() async {
    final current = _users.value.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    _users.value = AsyncReady(current.copyWith(isLoadingMore: true));
    try {
      final page = await model.listUsers(
        query: current.query,
        offset: current.users.length,
      );
      if (!isMounted) return;
      _users.value = AsyncReady(
        current.copyWith(
          users: [...current.users, ...page.users],
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      if (isMounted) _users.value = AsyncFailed(error, stackTrace);
    }
  }

  Future<void> setRole(AuthUser user, UserRole role) async {
    final current = _users.value.value;
    if (current == null) return;
    try {
      final updated = await model.setRole(user.id, role);
      if (!isMounted) return;
      _users.value = AsyncReady(
        current.copyWith(
          users: [
            for (final item in current.users)
              if (item.id == user.id) updated else item,
          ],
        ),
      );
      _showMessage('${user.email}: role ${role.wire}');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to change the role: $error');
    }
  }

  Future<void> _reload() async {
    final query = _query;
    final result = await AsyncState.guard(() async {
      final page = await model.listUsers(query: query);
      return AdminUsersState(
        users: page.users,
        total: page.total,
        query: query,
        hasMore: page.hasMore,
      );
    });
    if (isMounted) _users.value = result;
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreOffset) {
      unawaited(loadMore());
    }
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
