import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../widgets/splash_brand_mark.dart';
import '../widgets/splash_equalizer.dart';

/// Splash shown while the session is checked; the router navigates away.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const String routePath = '/splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBrand.surface,
      body: DecoratedBox(
        // Violet glow towards the top center.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 0.9,
            colors: [
              AppColors.dark.primary.withValues(alpha: 0.28),
              AppBrand.surface.withValues(alpha: 0),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SplashBrandMark(),
              const SizedBox(height: AppSpacing.s5),
              // The wordmark is tinted with the brand gradient through a mask.
              ShaderMask(
                shaderCallback: AppBrand.signGradient.createShader,
                child: Text(
                  'Shadowing',
                  style: AppText.displayLg.copyWith(
                    color: AppColors.dark.primaryOn,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Слушай. Повторяй.',
                style: AppText.label.copyWith(color: AppColors.dark.text3),
              ),
              const SizedBox(height: AppSpacing.s6),
              const SplashEqualizer(),
            ],
          ),
        ),
      ),
    );
  }
}
