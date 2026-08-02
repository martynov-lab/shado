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
/// разделам приложения (Уроки, Добавить, Прогресс и Настройки).
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Порядок совпадает с ветками [StatefulShellRoute] в роутере.
  static const List<MainShellDestination> destinations = [
    MainShellDestination(icon: AppIcons.list, label: 'Уроки'),
    MainShellDestination(icon: AppIcons.plus, label: 'Добавить'),
    MainShellDestination(icon: AppIcons.chart, label: 'Прогресс'),
    MainShellDestination(icon: AppIcons.settings, label: 'Настройки'),
  ];

  /// Индекс ветки «Добавить»: её пункт виден только тем, кто вправе создавать
  /// уроки, и в rail/sidebar он оформлен кнопкой, а не обычным разделом.
  static const int addIndex = 1;

  /// Индексы обычных разделов — всё, кроме «Добавить». По ним rail и sidebar
  /// рисуют пункты меню.
  static Iterable<int> get sectionIndexes =>
      [for (var i = 0; i < destinations.length; i++) i]
          .where((i) => i != addIndex);

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
