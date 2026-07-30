import 'package:flutter/material.dart';

import 'package:shado/core/theme/app_theme.dart' show WaveformColors;
import 'package:shado/theme/tokens/app_colors.dart';
import 'package:shado/theme/tokens/app_dimens.dart';
import 'package:shado/theme/tokens/app_shadows.dart';
import 'package:shado/theme/tokens/app_typography.dart';

/// Builds the app's [ThemeData]. `MaterialApp` is kept as the shell (routing,
/// localization, gestures), but every surface is driven by our own tokens, so
/// the look is fully custom rather than stock Material.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(Brightness.light, AppColors.light, AppShadows.light);
  static ThemeData dark() =>
      _build(Brightness.dark, AppColors.dark, AppShadows.dark);

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
      iconTheme: IconThemeData(color: c.text2, size: AppSizes.iconLg),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: AppSizes.borderThin,
        space: AppSizes.borderThin,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2.copyWith(color: c.text),
      ),
      // Стоковые поля ввода на остальных экранах должны попадать в ту же
      // сетку, что и AppTextField, иначе после смены темы они выбиваются.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        hintStyle: AppText.body.copyWith(color: c.text3),
        labelStyle: AppText.label.copyWith(color: c.text2),
        errorStyle: AppText.caption.copyWith(color: c.danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: c.border, width: AppSizes.borderThin),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: c.border, width: AppSizes.borderThin),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: c.primary, width: AppSizes.borderThick),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: c.danger, width: AppSizes.borderThin),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: c.danger, width: AppSizes.borderThick),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        titleTextStyle: AppText.h2.copyWith(color: c.text),
        contentTextStyle: AppText.body.copyWith(color: c.text2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceInv,
        contentTextStyle: AppText.body.copyWith(color: c.textInv),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
      ),
      extensions: <ThemeExtension<dynamic>>[c, s, _waveform(c)],
    );
  }

  /// Волна рисуется собственным painter'ом и читает цвета из [WaveformColors].
  /// Расширение остаётся зарегистрированным, но палитра теперь выводится из
  /// токенов, а не из стокового [ColorScheme].
  static WaveformColors _waveform(AppColors c) {
    return WaveformColors(
      wave: c.waveOn,
      activeSegment: c.primarySoft,
      boundary: c.accent,
      cursor: c.danger,
      background: c.surface2,
      trimHandle: c.warning,
      // Обрезаемые края гасим цветом фона, а не чёрным: так они уходят на
      // второй план и в светлой, и в тёмной теме.
      trimmedAway: c.bg.withValues(alpha: AppOpacities.scrim),
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
