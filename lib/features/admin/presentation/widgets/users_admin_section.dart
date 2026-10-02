import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../screens/admin_users_state.dart';
import 'admin_error_view.dart';
import 'user_tile.dart';
import 'users_list_footer.dart';

/// User list with search, paging and role changes.
class UsersAdminSection extends StatelessWidget {
  const UsersAdminSection({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.searchController,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onRoleChanged,
  });

  final AsyncState<AdminUsersState> users;

  /// The signed-in owner; their own role can't be changed.
  final String? currentUserId;

  final TextEditingController searchController;

  /// The next page loads when this list is scrolled near the end.
  final ScrollController scrollController;

  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final void Function(AuthUser user, UserRole role) onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by email',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: switch (users) {
            AsyncFailed(:final error) => AdminErrorView(
              error: error,
              onRetryPressed: onRefresh,
            ),
            AsyncReady(value: final data) when data.users.isEmpty => const Center(
              child: Text('No one found'),
            ),
            AsyncReady(value: final data) => RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                controller: scrollController,
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
                        isSelf: data.users[index].id == currentUserId,
                        onRoleChanged: (role) =>
                            onRoleChanged(data.users[index], role),
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
