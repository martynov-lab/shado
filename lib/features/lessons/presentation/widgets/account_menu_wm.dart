import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../screens/design_gallery/design_gallery_screen.dart';
import '../../../admin/presentation/screens/admin_users_page.dart';
import '../../../admin/presentation/screens/management_page.dart';
import '../../../auth/domain/entities/user_session.dart';
import 'account_menu.dart';
import 'account_menu_action.dart';
import 'account_menu_model.dart';

AccountMenuWidgetModel accountMenuWidgetModelFactory(BuildContext context) =>
    AccountMenuWidgetModel(
      AccountMenuModel(ProviderScope.containerOf(context, listen: false)),
    );

class AccountMenuWidgetModel
    extends WidgetModel<AccountMenu, AccountMenuModel> {
  AccountMenuWidgetModel(super.model);

  ValueListenable<UserSession> get session => model.session;

  Future<void> select(AccountMenuAction action) async {
    switch (action) {
      case AccountMenuAction.manage:
        await context.push<void>(ManagementPage.routePath);
      case AccountMenuAction.users:
        await context.push<void>(AdminUsersPage.routePath);
      case AccountMenuAction.designSystem:
        await context.push<void>(DesignGalleryScreen.routePath);
      case AccountMenuAction.signOut:
        await model.signOut();
    }
  }
}
