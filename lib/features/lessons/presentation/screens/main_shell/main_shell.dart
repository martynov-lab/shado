import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../widgets/main_shell_bottom_nav.dart';
import '../../widgets/main_shell_rail.dart';
import '../../widgets/main_shell_sidebar.dart';
import '../../widgets/offline_banner.dart';
import 'main_shell_destination.dart';
import 'main_shell_wm.dart';

/// App shell: bottom navigation, a rail or a sidebar depending on width.
class MainShell extends ElementaryWidget<MainShellWidgetModel> {
  const MainShell({super.key, required this.navigationShell})
    : super(mainShellWidgetModelFactory);

  final StatefulNavigationShell navigationShell;

  /// The order matches the [StatefulShellRoute] branches in the router.
  static const List<MainShellDestination> destinations = [
    MainShellDestination(icon: AppIcons.home, label: 'Home'),
    MainShellDestination(icon: AppIcons.list, label: 'Lessons'),
    MainShellDestination(icon: AppIcons.plus, label: 'Add'),
    MainShellDestination(icon: AppIcons.chart, label: 'Progress'),
    MainShellDestination(icon: AppIcons.settings, label: 'Settings'),
  ];

  /// Index of the add branch; its item is styled as a separate button.
  static const int addIndex = 2;

  /// Indexes of the regular sections — everything but add.
  static Iterable<int> get sectionIndexes => [
    for (var i = 0; i < destinations.length; i++) i,
  ].where((i) => i != addIndex);

  @override
  Widget build(MainShellWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.shell,
        wm.canAuthor,
        wm.email,
        wm.isOnline,
      ]),
      builder: (context, _) {
        final isOnline = wm.isOnline.value;
        final canAdd = wm.canAuthor.value && isOnline;
        final content = Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            // The banner already takes the top inset.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: !isOnline,
                child: wm.shell.value,
              ),
            ),
          ],
        );
        return Scaffold(
          backgroundColor: context.colors.bg,
          body: AppAdaptiveLayout(
            mobile: (_) => Column(
              children: [
                Expanded(child: content),
                MainShellBottomNav(
                  currentIndex: wm.currentIndex,
                  onSelected: wm.select,
                  canAdd: canAdd,
                ),
              ],
            ),
            tablet: (_) => Row(
              children: [
                MainShellRail(
                  currentIndex: wm.currentIndex,
                  onSelected: wm.select,
                  canAdd: canAdd,
                ),
                Expanded(child: content),
              ],
            ),
            desktop: (_) => Row(
              children: [
                MainShellSidebar(
                  currentIndex: wm.currentIndex,
                  onSelected: wm.select,
                  canAdd: canAdd,
                  email: wm.email.value,
                ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  }
}
