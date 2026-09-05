import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../pages/main_shell.dart';
import 'main_shell_brand.dart';

/// Tablet rail: the logo, section icons and the add button.
class MainShellRail extends StatelessWidget {
  const MainShellRail({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Whether to show the add button at the bottom of the rail.
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 74,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const MainShellBrand(),
              const SizedBox(height: AppSpacing.s4),
              for (final i in MainShell.sectionIndexes) ...[
                _RailItem(
                  icon: MainShell.destinations[i].icon,
                  label: MainShell.destinations[i].label,
                  selected: currentIndex == i,
                  onTap: () => onSelected(i),
                ),
                const SizedBox(height: AppSpacing.s2),
              ],
              const Spacer(),
              if (canAdd)
                AppIconButton(
                  icon: Icons.add_rounded,
                  semanticLabel: MainShell.destinations[MainShell.addIndex].label,
                  variant: AppButtonVariant.primary,
                  shape: AppIconButtonShape.square,
                  onPressed: () => onSelected(MainShell.addIndex),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? colors.primarySoft : Colors.transparent,
              borderRadius: AppRadii.rMd,
            ),
            child: Center(
              child: AppIcon(
                icon,
                size: AppSizes.iconLg,
                color: selected ? colors.primary : colors.text3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
