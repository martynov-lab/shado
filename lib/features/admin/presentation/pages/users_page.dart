import 'package:flutter/material.dart';

import '../widgets/users_admin_section.dart';

/// Пользователи сервиса и их роли. Раздел виден только владельцу.
///
/// Тело вынесено в [UsersAdminSection] — тем же списком владеет вкладка
/// «Управление». Отдельный маршрут оставлен как прямая точка входа.
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
