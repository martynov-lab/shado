import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/main_shell/main_shell.dart';
import 'main_shell_brand.dart';
import 'main_shell_rail_item.dart';

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
                MainShellRailItem(
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
                  semanticLabel:
                      MainShell.destinations[MainShell.addIndex].label,
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
