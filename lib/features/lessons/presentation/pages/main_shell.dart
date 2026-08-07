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
/// разделам приложения (Главная, Уроки, Добавить, Прогресс, Настройки и —
/// владельцу — Управление).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Порядок совпадает с ветками [StatefulShellRoute] в роутере.
  static const List<MainShellDestination> destinations = [
    MainShellDestination(icon: AppIcons.home, label: 'Главная'),
    MainShellDestination(icon: AppIcons.list, label: 'Уроки'),
    MainShellDestination(icon: AppIcons.plus, label: 'Добавить'),
    MainShellDestination(icon: AppIcons.chart, label: 'Прогресс'),
    MainShellDestination(icon: AppIcons.settings, label: 'Настройки'),
    MainShellDestination(icon: AppIcons.database, label: 'Управление'),
  ];

  /// Индекс ветки «Добавить»: её пункт виден только тем, кто вправе создавать
  /// уроки, и в rail/sidebar он оформлен кнопкой, а не обычным разделом. В
  /// нижней навигации телефона он по центру приподнятой кнопкой (FAB).
  static const int addIndex = 2;

  /// Индекс ветки «Управление»: её пункт виден только владельцу.
  static const int manageIndex = 5;

  /// Индексы обычных разделов — всё, кроме «Добавить». По ним rail и sidebar
  /// рисуют пункты меню. Пункт «Управление» из набора прячет сам виджет
  /// навигации, когда прав на него нет.
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
    // Роль могли изменить в админке (в т.ч. с другого устройства) — перечитываем
    // её при входе в оболочку, чтобы навигация подстроилась под свежие права.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).reloadUser();
    });
  }

  void _select(int index) => widget.navigationShell.goBranch(
    index,
    // Повторный тап по активной вкладке возвращает её к началу.
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    // «Добавить» — авторам (user-pro/admin/owner), «Управление» — владельцу.
    final canAdd = ref.watch(
      authControllerProvider.select((state) => state.canAuthor),
    );
    final canManage = ref.watch(
      authControllerProvider.select((state) => state.canManage),
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
              canManage: canManage,
            ),
          ],
        ),
        tablet: (context) => Row(
          children: [
            MainShellRail(
              currentIndex: index,
              onSelected: _select,
              canAdd: canAdd,
              canManage: canManage,
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
              canManage: canManage,
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
    );
  }
}
