import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/main_shell_bottom_nav.dart';
import '../widgets/main_shell_rail.dart';
import '../widgets/main_shell_sidebar.dart';

/// A navigation destination, also a [StatefulNavigationShell] branch.
class MainShellDestination {
  const MainShellDestination({required this.icon, required this.label});

  final AppIcons icon;
  final String label;
}

/// App shell: bottom navigation, a rail or a sidebar depending on width.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// The order matches the [StatefulShellRoute] branches in the router.
  static const List<MainShellDestination> destinations = [
    MainShellDestination(icon: AppIcons.home, label: 'Главная'),
    MainShellDestination(icon: AppIcons.list, label: 'Уроки'),
    MainShellDestination(icon: AppIcons.plus, label: 'Добавить'),
    MainShellDestination(icon: AppIcons.chart, label: 'Прогресс'),
    MainShellDestination(icon: AppIcons.settings, label: 'Настройки'),
  ];

  /// Index of the add branch; its item is styled as a separate button.
  static const int addIndex = 2;

  /// Indexes of the regular sections — everything but add.
  static Iterable<int> get sectionIndexes =>
      [for (var i = 0; i < destinations.length; i++) i]
          .where((i) => i != addIndex);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // The role could change in the admin panel — re-read it on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).reloadUser();
    });
  }

  void _select(int index) => widget.navigationShell.goBranch(
    index,
    // Tapping the active tab again returns it to the start.
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    // The add tab is shown to authors only.
    final canAdd = ref.watch(
      authControllerProvider.select((state) => state.canAuthor),
    );

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: AppAdaptiveLayout(
        mobile: (context) => Column(
          children: [
            Expanded(child: widget.navigationShell),
            MainShellBottomNav(
              currentIndex: index,
              onSelected: _select,
              canAdd: canAdd,
            ),
          ],
        ),
        tablet: (context) => Row(
          children: [
            MainShellRail(
              currentIndex: index,
              onSelected: _select,
              canAdd: canAdd,
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
        desktop: (context) => Row(
          children: [
            MainShellSidebar(
              currentIndex: index,
              onSelected: _select,
              canAdd: canAdd,
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
    );
  }
}
