import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../screens/design_gallery/design_gallery_screen.dart';
import '../../../admin/presentation/pages/management_page.dart';
import '../../../admin/presentation/pages/users_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Account menu: who is signed in, sign-out and the owner sections.
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
          case 'manage':
            context.push(ManagementPage.routePath);
          case 'users':
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
        // Owner sections; the server checks the rights anyway.
        if (auth.isOwner) ...[
          const PopupMenuItem(
            value: 'manage',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tune),
              title: Text('Управление'),
            ),
          ),
          const PopupMenuItem(
            value: 'users',
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
