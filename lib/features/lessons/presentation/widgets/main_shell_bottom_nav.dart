import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../pages/main_shell.dart';

/// Нижняя навигация телефона: поверхность surface с верхней границей и ряд
/// пунктов из [MainShell.destinations].
class MainShellBottomNav extends StatelessWidget {
  const MainShellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Показывать ли пункт «Добавить»: он только у тех, кто вправе создавать
  /// уроки.
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
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
                if (canAdd || i != MainShell.addIndex)
                  Expanded(
                    child: _BottomNavItem(
                      destination: MainShell.destinations[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
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
