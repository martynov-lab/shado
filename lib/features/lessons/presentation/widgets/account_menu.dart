import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'account_menu_action.dart';
import 'account_menu_wm.dart';

/// Account menu: who is signed in, sign-out and the owner sections.
class AccountMenu extends ElementaryWidget<AccountMenuWidgetModel> {
  const AccountMenu({super.key}) : super(accountMenuWidgetModelFactory);

  @override
  Widget build(AccountMenuWidgetModel wm) {
    return ValueListenableBuilder(
      valueListenable: wm.session,
      builder: (_, session, _) {
        final email = session.user?.email ?? '';
        return PopupMenuButton<AccountMenuAction>(
          tooltip: email.isEmpty ? 'Account' : email,
          icon: const Icon(Icons.account_circle_outlined),
          onSelected: wm.select,
          itemBuilder: (_) => [
            if (email.isNotEmpty)
              PopupMenuItem(
                enabled: false,
                child: Text(email, overflow: TextOverflow.ellipsis),
              ),
            // Owner sections; the server checks the rights anyway.
            if (session.isOwner) ...[
              const PopupMenuItem(
                value: AccountMenuAction.manage,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.tune),
                  title: Text('Management'),
                ),
              ),
              const PopupMenuItem(
                value: AccountMenuAction.users,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.people_outline),
                  title: Text('Users'),
                ),
              ),
              const PopupMenuItem(
                value: AccountMenuAction.designSystem,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Design system'),
                ),
              ),
            ],
            const PopupMenuItem(
              value: AccountMenuAction.signOut,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout),
                title: Text('Sign out'),
              ),
            ),
          ],
        );
      },
    );
  }
}
