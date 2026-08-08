import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../pages/main_shell.dart';

/// Нижняя навигация телефона: поверхность surface с верхней границей и ряд
/// пунктов из [MainShell.destinations]. Пункт «Добавить» ([MainShell.addIndex])
/// по центру оформлен приподнятой круглой кнопкой (FAB) и виден только тем, кто
/// вправе создавать уроки.
class MainShellBottomNav extends StatelessWidget {
  const MainShellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Показывать ли центральный FAB «Добавить».
  final bool canAdd;

  /// Диаметр FAB и то, насколько он выступает над баром.
  static const double _fabSize = 52;
  static const double _fabOverhang = 18;

  @override
  Widget build(BuildContext context) {
    final bar = _bar(context);
    // Без FAB бар остаётся обычной полосой — центральный слот не резервируем.
    if (!canAdd) return bar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Бар опускаем на высоту выступа, чтобы FAB целиком помещался в границы
        // виджета и оставался нажимаемым по всей площади.
        Padding(
          padding: const EdgeInsets.only(top: _fabOverhang),
          child: bar,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: _BottomNavFab(
              size: _fabSize,
              onTap: () => onSelected(MainShell.addIndex),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2,
            vertical: AppSpacing.s2,
          ),
          child: Row(
            children: [
              for (var i = 0; i < MainShell.destinations.length; i++)
                if (i != MainShell.addIndex)
                  Expanded(
                    child: _BottomNavItem(
                      destination: MainShell.destinations[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  )
                // Центральный слот резервируем под FAB, только если он показан.
                else if (canAdd)
                  const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final MainShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = selected ? colors.primary : colors.text3;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(destination.icon, size: AppSizes.iconLg, color: tint),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  destination.label,
                  style: AppText.caption.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Приподнятая круглая кнопка «Добавить» в центре нижней навигации: брендовый
/// градиент в кольце цвета фона — как `nav-fab` в макете.
class _BottomNavFab extends StatelessWidget {
  const _BottomNavFab({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: MainShell.destinations[MainShell.addIndex].label,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppBrand.signGradient,
          shape: BoxShape.circle,
          border: Border.all(color: colors.bg, width: 4),
          boxShadow: context.shadows.e2,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: AppIcon(
                AppIcons.plus,
                size: AppSizes.iconLg,
                color: colors.primaryOn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
