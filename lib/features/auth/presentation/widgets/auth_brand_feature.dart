import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Feature row on the brand panel: an icon tile and a caption.
class AuthBrandFeature extends StatelessWidget {
  const AuthBrandFeature({super.key, required this.icon, required this.label});

  final AppIcons icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          width: AppSizes.controlSm,
          height: AppSizes.controlSm,
          decoration: BoxDecoration(
            borderRadius: AppRadii.rSm,
            // The tile is a light overlay on top of the gradient.
            color: colors.primaryOn.withValues(
              alpha: AppOpacities.pressOnPrimary,
            ),
          ),
          child: Center(
            child: AppIcon(
              icon,
              size: AppSizes.iconMd,
              color: colors.primaryOn,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Text(
            label,
            style: AppText.label.copyWith(color: colors.primaryOn),
          ),
        ),
      ],
    );
  }
}
