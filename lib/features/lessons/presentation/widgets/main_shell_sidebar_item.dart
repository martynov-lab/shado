import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/main_shell/main_shell_destination.dart';

/// A section in the desktop sidebar.
class MainShellSidebarItem extends StatelessWidget {
  const MainShellSidebarItem({
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
    final tint = selected ? colors.primary : colors.text2;

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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            decoration: BoxDecoration(
              color: selected ? colors.primarySoft : Colors.transparent,
              borderRadius: AppRadii.rMd,
            ),
            child: Row(
              children: [
                AppIcon(destination.icon, size: AppSizes.iconMd, color: tint),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  destination.label,
                  style: AppText.label.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
