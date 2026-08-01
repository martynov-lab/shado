import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'auth_brand_surface.dart';

/// Знак Shadowing: волна на фирменном градиенте.
class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({
    super.key,
    this.size = AppSizes.controlLg,
    this.iconSize = AppSizes.iconLg,
    this.borderRadius = AppRadii.rLg,
  });

  final double size;
  final double iconSize;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: borderRadius,
      boxShadow: context.shadows.e2,
    ),
    child: AuthBrandSurface(
      borderRadius: borderRadius,
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: AppIcon(
            AppIcons.logoWave,
            size: iconSize,
            color: context.colors.primaryOn,
          ),
        ),
      ),
    ),
  );
}
