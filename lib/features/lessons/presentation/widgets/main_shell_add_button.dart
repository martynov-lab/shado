import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/main_shell/main_shell.dart';

/// Raised round add button in the center of the bottom navigation.
class MainShellAddButton extends StatelessWidget {
  const MainShellAddButton({
    super.key,
    required this.size,
    required this.onTap,
  });

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
