import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../admin_controller.dart';

/// Пользователи сервиса и их роли. Раздел виден только владельцу.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Свою роль могли снять с другого устройства: перечитываем её при входе в
    // раздел, чтобы он закрылся сам.
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
      _showMessage('${user.email}: роль ${role.name}');
    } on ApiException catch (error) {
      // Понизить владельца, заданного в конфигурации сервера, нельзя — сервер
      // отвечает 422 с объяснением.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
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
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(
          error: error,
          onRetry: controller.refresh,
        ),
        data: (data) {
          if (data.users.isEmpty) {
            return const Center(child: Text('Никого не нашлось'));
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: data.users.length + 1,
              itemBuilder: (context, index) {
                if (index == data.users.length) {
                  return _ListFooter(state: data);
                }
                final user = data.users[index];
                return _UserTile(
                  user: user,
                  isSelf: user.id == currentUser?.id,
                  onRoleChanged: (role) => _setRole(user, role),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
  });

  final AuthUser user;
  final bool isSelf;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        child: Icon(user.isOwner ? Icons.shield_outlined : Icons.person_outline),
      ),
      title: Text(user.email, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        isSelf ? 'это вы · ${user.role.name}' : user.role.name,
        style: theme.textTheme.bodySmall,
      ),
      trailing: SegmentedButton<UserRole>(
        segments: const [
          ButtonSegment(value: UserRole.user, label: Text('user')),
          ButtonSegment(value: UserRole.owner, label: Text('owner')),
        ],
        selected: {user.role},
        showSelectedIcon: false,
        onSelectionChanged: (roles) => onRoleChanged(roles.first),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state});

  final AdminUsersState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: state.isLoadingMore
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Показано ${state.users.length} из ${state.total}',
                style: theme.textTheme.bodySmall,
              ),
      ),
    );
  }
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    // 403 здесь означает, что роль сняли только что: раздел просто закрывается
    // по возврату на главную, роутер уведёт сам.
    final isForbidden =
        error is ApiException && (error as ApiException).status == 403;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isForbidden
                  ? 'Раздел доступен только владельцу'
                  : 'Не удалось получить список: $error',
              textAlign: TextAlign.center,
            ),
            if (!isForbidden) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
