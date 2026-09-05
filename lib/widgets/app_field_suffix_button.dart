import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_icon.dart';

/// Tappable icon on the right inside a text field.
class AppFieldSuffixButton extends StatelessWidget {
  const AppFieldSuffixButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final AppIcons icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: AppSizes.iconLg,
        child: AppIcon(
          icon,
          size: AppSizes.iconMd,
          color: context.colors.text2,
        ),
      ),
    );
  }
}
