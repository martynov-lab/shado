import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../admin_controller.dart';
import 'admin_error_view.dart';
import 'user_tile.dart';
import 'users_list_footer.dart';

/// User list with search, paging and role changes.
class UsersAdminSection extends ConsumerStatefulWidget {
  const UsersAdminSection({super.key});

  @override
  ConsumerState<UsersAdminSection> createState() => _UsersAdminSectionState();
}

class _UsersAdminSectionState extends ConsumerState<UsersAdminSection> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The role could be revoked from another device — re-read it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).reloadUser();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      ref.read(adminUsersControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _setRole(AuthUser user, UserRole role) async {
    try {
      await ref
          .read(adminUsersControllerProvider.notifier)
          .setRole(user.id, role);
      if (!mounted) return;
      _showMessage('${user.email}: роль ${role.wire}');
    } on ApiException catch (error) {
      // The server explains the refusal — show its message.
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Не удалось изменить роль: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersControllerProvider);
    final controller = ref.read(adminUsersControllerProvider.notifier);
    final currentUser = ref.watch(authControllerProvider).user;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Поиск по email',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: controller.search,
          ),
        ),
        Expanded(
          child: switch (state) {
            AsyncError(:final error) => AdminErrorView(
              error: error,
              onRetryPressed: controller.refresh,
            ),
            AsyncData(value: final data) when data.users.isEmpty => const Center(
              child: Text('Никого не нашлось'),
            ),
            AsyncData(value: final data) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                controller: _scrollController,
                // One extra item at the end is the list footer.
                itemCount: data.users.length + 1,
                itemBuilder: (context, index) => index == data.users.length
                    ? UsersListFooter(
                        shownCount: data.users.length,
                        totalCount: data.total,
                        isLoadingMore: data.isLoadingMore,
                      )
                    : UserTile(
                        user: data.users[index],
                        isSelf: data.users[index].id == currentUser?.id,
                        onRoleChanged: (role) =>
                            _setRole(data.users[index], role),
                      ),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}
