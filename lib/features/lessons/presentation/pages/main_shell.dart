import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/main_shell_bottom_nav.dart';
import '../widgets/main_shell_rail.dart';
import '../widgets/main_shell_sidebar.dart';

/// Один пункт навигации: он же ветка [StatefulNavigationShell].
class MainShellDestination {
  const MainShellDestination({required this.icon, required this.label});

  final AppIcons icon;
  final String label;
}

/// Каркас приложения: нижняя навигация на телефоне, вертикальный rail на
/// планшете и sidebar на десктопе. Пункты ведут по веткам go_router — реальным
/// разделам приложения (Уроки и Добавить).
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Порядок совпадает с ветками [StatefulShellRoute] в роутере.
  static const List<MainShellDestination> destinations = [
    MainShellDestination(icon: AppIcons.list, label: 'Уроки'),
    MainShellDestination(icon: AppIcons.plus, label: 'Добавить'),
  ];

  /// Индекс ветки «Добавить»: её пункт виден только тем, кто вправе создавать
  /// уроки.
  static const int addIndex = 1;

  void _select(int index) => navigationShell.goBranch(
    index,
    // Повторный тап по активной вкладке возвращает её к началу.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    // Добавлять уроки может только владелец — остальным пункт «Добавить» не
    // показываем.
    final canAdd = ref.watch(
      authControllerProvider.select((state) => state.isOwner),
    );

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: AppAdaptiveLayout(
        mobile: (context) => Column(
          children: [
            Expanded(child: navigationShell),
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
            Expanded(child: navigationShell),
          ],
        ),
        desktop: (context) => Row(
          children: [
            MainShellSidebar(
              currentIndex: index,
              onSelected: _select,
              canAdd: canAdd,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
