import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../screens/design_gallery/design_gallery_screen.dart';
import '../../../admin/presentation/pages/users_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Кто вошёл, выход и — владельцу — раздел с пользователями.
///
/// Сессию читает сам: меню аккаунта отвечает за неё целиком, и экрану знать о
/// ней незачем.
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final email = auth.user?.email ?? '';

    return PopupMenuButton<String>(
      tooltip: email.isEmpty ? 'Аккаунт' : email,
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) async {
        switch (value) {
          case 'admin':
            context.push(AdminUsersPage.routePath);
          case 'design':
            context.push(DesignGalleryScreen.routePath);
          case 'logout':
            await ref.read(authControllerProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        if (email.isNotEmpty)
          PopupMenuItem(
            enabled: false,
            child: Text(email, overflow: TextOverflow.ellipsis),
          ),
        // Раздел показываем владельцу, но полагаться на это как на защиту
        // нельзя: роль проверяет сервер.
        if (auth.isOwner) ...[
          const PopupMenuItem(
            value: 'admin',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_outline),
              title: Text('Пользователи'),
            ),
          ),
          const PopupMenuItem(
            value: 'design',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette_outlined),
              title: Text('Дизайн-система'),
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
          ),
        ),
      ],
    );
  }
}
