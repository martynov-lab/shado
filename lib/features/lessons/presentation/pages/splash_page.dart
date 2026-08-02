import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../widgets/splash_brand_mark.dart';
import '../widgets/splash_equalizer.dart';

/// Заставка на время, пока приложение выясняет, жива ли сессия: на старте оно
/// меняет сохранённый refresh-токен на access и спрашивает `/v1/me`.
///
/// Рисуется поверх нативного сплеша на том же тёмном фоне, поэтому переход
/// незаметен. Уводит с заставки роутер (по итогам проверки сессии), а не сам
/// экран, — здесь только брендовая разметка и живой эквалайзер ожидания.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const String routePath = '/splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBrand.surface,
      body: DecoratedBox(
        // Фиолетовое свечение к центру-верху собирает взгляд на знаке.
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
              // Вордмарк перекрашиваем фирменным градиентом через маску.
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
