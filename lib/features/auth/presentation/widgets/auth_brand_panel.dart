import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'auth_brand_feature.dart';
import 'auth_brand_row.dart';
import 'auth_brand_surface.dart';
import 'auth_brand_wave.dart';

/// Левая половина десктопного экрана: рассказ о продукте на градиенте.
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
                ? 'Освой естественный ритм английской речи'
                : 'Говори по-английски, повторяя за носителями',
            style: AppText.h1.copyWith(color: colors.primaryOn),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Техника shadowing: разбей дорожку на короткие сегменты, слушай '
            'и повторяй, копируя интонацию.',
            style: AppText.body.copyWith(color: colors.primaryOn),
          ),
          const SizedBox(height: AppSpacing.s5),
          const AuthBrandWave(),
          const SizedBox(height: AppSpacing.s5),
          const AuthBrandFeature(
            icon: AppIcons.headphones,
            label: 'Локальная библиотека уроков — без сети',
          ),
          const SizedBox(height: AppSpacing.s3),
          const AuthBrandFeature(
            icon: AppIcons.waveform,
            label: 'Ручная разбивка речи на сегменты',
          ),
          const SizedBox(height: AppSpacing.s3),
          const AuthBrandFeature(
            icon: AppIcons.flame,
            label: 'Серии и прогресс, чтобы не бросать',
          ),
        ],
      ),
    );
  }
}
