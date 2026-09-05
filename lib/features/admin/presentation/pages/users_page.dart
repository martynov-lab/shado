import 'package:flutter/material.dart';

import '../widgets/users_admin_section.dart';

/// Owner screen with the user list and their roles.
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
