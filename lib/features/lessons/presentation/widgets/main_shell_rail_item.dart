import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A section in the tablet rail.
class MainShellRailItem extends StatelessWidget {
  const MainShellRailItem({
    super.key,
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
