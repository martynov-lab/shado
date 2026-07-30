import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_shadows.dart';
import 'tokens/app_typography.dart';

/// Builds the app's [ThemeData]. `MaterialApp` is kept as the shell (routing,
/// localization, gestures), but every surface is driven by our own tokens, so
/// the look is fully custom rather than stock Material.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light, AppShadows.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark, AppShadows.dark);

  static ThemeData _build(Brightness brightness, AppColors c, AppShadows s) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: c.primaryOn,
      secondary: c.accent,
      onSecondary: c.primaryOn,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
      onError: c.primaryOn,
      outline: c.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: AppText.textFamily,
      textTheme: _textTheme(c),
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[c, s],
    );
  }

  static TextTheme _textTheme(AppColors c) {
    final t = c.text;
    return TextTheme(
      displayLarge: AppText.displayLg.copyWith(color: t),
      headlineLarge: AppText.h1.copyWith(color: t),
      headlineMedium: AppText.h1.copyWith(color: t),
      headlineSmall: AppText.h2.copyWith(color: t),
      titleLarge: AppText.title.copyWith(color: t),
      titleMedium: AppText.label.copyWith(color: t),
      bodyLarge: AppText.body.copyWith(color: t),
      bodyMedium: AppText.body.copyWith(color: t),
      bodySmall: AppText.caption.copyWith(color: c.text2),
      labelLarge: AppText.label.copyWith(color: t),
      labelMedium: AppText.caption.copyWith(color: c.text2),
    );
  }
}
