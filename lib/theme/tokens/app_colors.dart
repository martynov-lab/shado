import 'package:flutter/material.dart';

/// App color tokens; widgets read them through `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryHover,
    required this.primaryPress,
    required this.primarySoft,
    required this.primaryOn,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surfaceInv,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.textInv,
    required this.waveOn,
    required this.waveOff,
  });

  // Brand and accent
  final Color primary;
  final Color primaryHover;
  final Color primaryPress;
  final Color primarySoft;
  final Color primaryOn;
  final Color accent;
  final Color accentSoft;

  // Semantic
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;

  // Surfaces
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surfaceInv; // dark player surface

  // Borders
  final Color border;
  final Color borderStrong;

  // Text
  final Color text;
  final Color text2;
  final Color text3;
  final Color textInv;

  // Waveform
  final Color waveOn;
  final Color waveOff;

  static const AppColors light = AppColors(
    primary: Color(0xFF7C5CFF),
    primaryHover: Color(0xFF6A46F0),
    primaryPress: Color(0xFF5B37D6),
    primarySoft: Color(0xFFEDE8FF),
    primaryOn: Color(0xFFFFFFFF),
    accent: Color(0xFFFF6B9D),
    accentSoft: Color(0xFFFFE4EE),
    success: Color(0xFF22C58B),
    successSoft: Color(0xFFDDF7EE),
    warning: Color(0xFFF5A524),
    warningSoft: Color(0xFFFDEFD5),
    danger: Color(0xFFF43F5E),
    dangerSoft: Color(0xFFFEE1E6),
    bg: Color(0xFFF4F2FC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFAF9FF),
    surfaceInv: Color(0xFF171425),
    border: Color(0xFFE7E2F5),
    borderStrong: Color(0xFFD6CFEC),
    text: Color(0xFF1A1626),
    text2: Color(0xFF635C7A),
    text3: Color(0xFF9A93AD),
    textInv: Color(0xFFF7F5FF),
    waveOn: Color(0xFF7C5CFF),
    waveOff: Color(0xFFD8D1EE),
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF8B70FF),
    primaryHover: Color(0xFF9B84FF),
    primaryPress: Color(0xFF7C5CFF),
    primarySoft: Color(0xFF251F3D),
    primaryOn: Color(0xFFFFFFFF),
    accent: Color(0xFFFF7CA8),
    accentSoft: Color(0xFF33202C),
    success: Color(0xFF34D9A0),
    successSoft: Color(0xFF16302A),
    warning: Color(0xFFF7B54A),
    warningSoft: Color(0xFF332810),
    danger: Color(0xFFFB5C74),
    dangerSoft: Color(0xFF351920),
    bg: Color(0xFF100E18),
    surface: Color(0xFF1A1726),
    surface2: Color(0xFF221E33),
    surfaceInv: Color(0xFFF7F5FF),
    border: Color(0xFF2C2740),
    borderStrong: Color(0xFF3A3452),
    text: Color(0xFFF5F3FB),
    text2: Color(0xFFB2AAC8),
    text3: Color(0xFF7B7494),
    textInv: Color(0xFF171425),
    waveOn: Color(0xFF8B70FF),
    waveOff: Color(0xFF342E4B),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primaryPress,
    Color? primarySoft,
    Color? primaryOn,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surfaceInv,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? text2,
    Color? text3,
    Color? textInv,
    Color? waveOn,
    Color? waveOff,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPress: primaryPress ?? this.primaryPress,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryOn: primaryOn ?? this.primaryOn,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surfaceInv: surfaceInv ?? this.surfaceInv,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      textInv: textInv ?? this.textInv,
      waveOn: waveOn ?? this.waveOn,
      waveOff: waveOff ?? this.waveOff,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPress: Color.lerp(primaryPress, other.primaryPress, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryOn: Color.lerp(primaryOn, other.primaryOn, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surfaceInv: Color.lerp(surfaceInv, other.surfaceInv, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      textInv: Color.lerp(textInv, other.textInv, t)!,
      waveOn: Color.lerp(waveOn, other.waveOn, t)!,
      waveOff: Color.lerp(waveOff, other.waveOff, t)!,
    );
  }
}
