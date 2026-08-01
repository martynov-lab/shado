import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Строка списка возможностей на брендовой панели: иконка в плитке и подпись.
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
            // Плитка — светлый оверлей поверх градиента, а не отдельный цвет.
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
