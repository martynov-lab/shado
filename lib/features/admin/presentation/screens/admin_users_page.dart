import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import '../widgets/users_admin_section.dart';
import 'admin_users_wm.dart';

/// Owner screen with the user list and their roles.
class AdminUsersPage extends ElementaryWidget<AdminUsersWidgetModel> {
  const AdminUsersPage({super.key}) : super(adminUsersWidgetModelFactory);

  static const String routePath = '/admin/users';

  @override
  Widget build(AdminUsersWidgetModel wm) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([wm.users, wm.currentUserId]),
          builder: (_, _) => UsersAdminSection(
            users: wm.users.value,
            currentUserId: wm.currentUserId.value,
            searchController: wm.searchController,
            scrollController: wm.scrollController,
            onSearchChanged: wm.search,
            onRefresh: wm.refresh,
            onRoleChanged: (user, role) => unawaited(wm.setRole(user, role)),
          ),
        ),
      ),
    );
  }
}
