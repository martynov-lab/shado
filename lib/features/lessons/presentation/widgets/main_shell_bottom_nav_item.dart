import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/main_shell/main_shell_destination.dart';

/// A section in the bottom navigation: an icon over its name.
class MainShellBottomNavItem extends StatelessWidget {
  const MainShellBottomNavItem({
    super.key,
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
