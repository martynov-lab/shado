import 'package:flutter/material.dart';

import '../screens/main_shell/main_shell.dart';
import 'main_shell_add_button.dart';
import 'main_shell_bottom_bar.dart';

/// Phone bottom navigation; the centered add item is a raised button.
class MainShellBottomNav extends StatelessWidget {
  const MainShellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Whether to show the center add FAB.
  final bool canAdd;

  /// FAB diameter and how far it sticks out above the bar.
  static const double _fabSize = 52;
  static const double _fabOverhang = 18;

  @override
  Widget build(BuildContext context) {
    final bar = MainShellBottomBar(
      currentIndex: currentIndex,
      onSelected: onSelected,
      canAdd: canAdd,
    );
    // Without the FAB the bar is a plain strip and needs no center slot.
    if (!canAdd) return bar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lower the bar by the overhang so the button fits inside it.
        Padding(
          padding: const EdgeInsets.only(top: _fabOverhang),
          child: bar,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: MainShellAddButton(
              size: _fabSize,
              onTap: () => onSelected(MainShell.addIndex),
            ),
          ),
        ),
      ],
    );
  }
}
