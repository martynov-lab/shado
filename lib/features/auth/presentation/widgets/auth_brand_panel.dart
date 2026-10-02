import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'auth_brand_feature.dart';
import 'auth_brand_row.dart';
import 'auth_brand_surface.dart';
import 'auth_brand_wave.dart';

/// Left half of the desktop screen: the product pitch on a gradient.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, required this.isRegistration});

  final bool isRegistration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AuthBrandSurface(
      decorated: true,
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthBrandRow(),
          const Spacer(),
          Text(
            isRegistration
                ? 'Master the natural rhythm of spoken English'
                : 'Speak English by repeating after native speakers',
            style: AppText.h1.copyWith(color: colors.primaryOn),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'The shadowing technique: split a track into short segments, listen '
            'and repeat, copying the intonation.',
            style: AppText.body.copyWith(color: colors.primaryOn),
          ),
          const SizedBox(height: AppSpacing.s5),
          const AuthBrandWave(),
          const SizedBox(height: AppSpacing.s5),
          const AuthBrandFeature(
            icon: AppIcons.headphones,
            label: 'Local lesson library — works offline',
          ),
          const SizedBox(height: AppSpacing.s3),
          const AuthBrandFeature(
            icon: AppIcons.waveform,
            label: 'Manual splitting of speech into segments',
          ),
          const SizedBox(height: AppSpacing.s3),
          const AuthBrandFeature(
            icon: AppIcons.flame,
            label: 'Streaks and progress to keep you going',
          ),
        ],
      ),
    );
  }
}
