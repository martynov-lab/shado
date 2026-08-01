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

  static ThemeData _build(
    Brightness brightness,
    AppColors colors,
    AppShadows shadows,
  ) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.primaryOn,
          secondary: colors.accent,
          onSecondary: colors.primaryOn,
          surface: colors.surface,
          onSurface: colors.text,
          error: colors.danger,
          onError: colors.primaryOn,
          outline: colors.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      fontFamily: AppText.textFamily,
      textTheme: _textTheme(colors),
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: colors.text2, size: AppSizes.iconLg),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: AppSizes.borderThin,
        space: AppSizes.borderThin,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2.copyWith(color: colors.text),
      ),
      // Стоковые поля ввода на остальных экранах должны попадать в ту же
      // сетку, что и AppTextField, иначе после смены темы они выбиваются.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface2,
        hintStyle: AppText.body.copyWith(color: colors.text3),
        labelStyle: AppText.label.copyWith(color: colors.text2),
        errorStyle: AppText.caption.copyWith(color: colors.danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(
            color: colors.border,
            width: AppSizes.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(
            color: colors.border,
            width: AppSizes.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(
            color: colors.primary,
            width: AppSizes.borderThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(
            color: colors.danger,
            width: AppSizes.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(
            color: colors.danger,
            width: AppSizes.borderThick,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        titleTextStyle: AppText.h2.copyWith(color: colors.text),
        contentTextStyle: AppText.body.copyWith(color: colors.text2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceInv,
        contentTextStyle: AppText.body.copyWith(color: colors.textInv),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, shadows, _waveform(colors)],
    );
  }

  /// Волна рисуется собственным painter'ом и читает цвета из [WaveformColors].
  /// Расширение остаётся зарегистрированным, но палитра теперь выводится из
  /// токенов, а не из стокового [ColorScheme].
  static WaveformColors _waveform(AppColors colors) {
    return WaveformColors(
      wave: colors.waveOn,
      activeSegment: colors.primarySoft,
      boundary: colors.accent,
      cursor: colors.danger,
      background: colors.surface2,
      trimHandle: colors.warning,
      // Обрезаемые края гасим цветом фона, а не чёрным: так они уходят на
      // второй план и в светлой, и в тёмной теме.
      trimmedAway: colors.bg.withValues(alpha: AppOpacities.scrim),
    );
  }

  static TextTheme _textTheme(AppColors colors) {
    final textColor = colors.text;
    return TextTheme(
      displayLarge: AppText.displayLg.copyWith(color: textColor),
      headlineLarge: AppText.h1.copyWith(color: textColor),
      headlineMedium: AppText.h1.copyWith(color: textColor),
      headlineSmall: AppText.h2.copyWith(color: textColor),
      titleLarge: AppText.title.copyWith(color: textColor),
      titleMedium: AppText.label.copyWith(color: textColor),
      bodyLarge: AppText.body.copyWith(color: textColor),
      bodyMedium: AppText.body.copyWith(color: textColor),
      bodySmall: AppText.caption.copyWith(color: colors.text2),
      labelLarge: AppText.label.copyWith(color: textColor),
      labelMedium: AppText.caption.copyWith(color: colors.text2),
    );
  }
}
