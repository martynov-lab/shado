import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../screens/main_shell/main_shell.dart';
import 'main_shell_bottom_nav_item.dart';

/// The strip of the bottom navigation; the center slot stays empty for the
/// add button when [canAdd] is set.
class MainShellBottomBar extends StatelessWidget {
  const MainShellBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
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
                if (i != MainShell.addIndex)
                  Expanded(
                    child: MainShellBottomNavItem(
                      destination: MainShell.destinations[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  )
                // The center slot is reserved for the FAB when shown.
                else if (canAdd)
                  const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
