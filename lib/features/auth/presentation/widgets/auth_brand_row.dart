import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_logo_mark.dart';

/// Логотип с названием — шапка брендового блока на планшете и десктопе.
class AuthBrandRow extends StatelessWidget {
  const AuthBrandRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthLogoMark(
          size: AppSizes.controlSm,
          iconSize: AppSizes.iconMd,
          borderRadius: AppRadii.rMd,
        ),
        const SizedBox(width: AppSpacing.s3),
        Text(
          'Shadowing',
          style: AppText.title.copyWith(color: context.colors.primaryOn),
        ),
      ],
    );
  }
}
