import 'package:flutter/material.dart';

import '../widgets/users_admin_section.dart';

/// Пользователи сервиса и их роли. Экран владельца, открывается из меню
/// аккаунта (пункт «Пользователи»).
///
/// Тело вынесено в [UsersAdminSection]; каркас (Scaffold, AppBar) — здесь.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  static const String routePath = '/admin/users';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: const SafeArea(child: UsersAdminSection()),
    );
  }
}
