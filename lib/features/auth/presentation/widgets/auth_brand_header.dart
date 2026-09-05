import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_brand_row.dart';
import 'auth_brand_surface.dart';

/// Login card header on tablets: logo and tagline on a gradient.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, required this.isRegistration});

  final bool isRegistration;

  @override
  Widget build(BuildContext context) {
    return AuthBrandSurface(
      decorated: true,
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthBrandRow(),
          const SizedBox(height: AppSpacing.s4),
          Text(
            isRegistration
                ? 'Слушай. Повторяй.\nНачни говорить свободнее.'
                : 'Слушай. Повторяй.\nПродолжай тренировку.',
            style: AppText.h2.copyWith(color: context.colors.primaryOn),
          ),
        ],
      ),
    );
  }
}
