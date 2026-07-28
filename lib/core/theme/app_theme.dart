import 'package:flutter/material.dart';

/// Цвета, к которым обращается отрисовка волны.
class WaveformColors extends ThemeExtension<WaveformColors> {
  const WaveformColors({
    required this.wave,
    required this.activeSegment,
    required this.boundary,
    required this.cursor,
    required this.background,
    required this.trimHandle,
    required this.trimmedAway,
  });

  final Color wave;
  final Color activeSegment;
  final Color boundary;
  final Color cursor;
  final Color background;

  /// Метки обрезки со стрелочками.
  final Color trimHandle;

  /// Затемнение по краям волны — то, что обрезка отрежет.
  final Color trimmedAway;

  @override
  WaveformColors copyWith({
    Color? wave,
    Color? activeSegment,
    Color? boundary,
    Color? cursor,
    Color? background,
    Color? trimHandle,
    Color? trimmedAway,
  }) {
    return WaveformColors(
      wave: wave ?? this.wave,
      activeSegment: activeSegment ?? this.activeSegment,
      boundary: boundary ?? this.boundary,
      cursor: cursor ?? this.cursor,
      background: background ?? this.background,
      trimHandle: trimHandle ?? this.trimHandle,
      trimmedAway: trimmedAway ?? this.trimmedAway,
    );
  }

  @override
  WaveformColors lerp(WaveformColors? other, double t) {
    if (other == null) return this;
    return WaveformColors(
      wave: Color.lerp(wave, other.wave, t)!,
      activeSegment: Color.lerp(activeSegment, other.activeSegment, t)!,
      boundary: Color.lerp(boundary, other.boundary, t)!,
      cursor: Color.lerp(cursor, other.cursor, t)!,
      background: Color.lerp(background, other.background, t)!,
      trimHandle: Color.lerp(trimHandle, other.trimHandle, t)!,
      trimmedAway: Color.lerp(trimmedAway, other.trimmedAway, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF3D5AFE);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      extensions: <ThemeExtension<dynamic>>[
        WaveformColors(
          wave: scheme.primary.withValues(alpha: 0.65),
          activeSegment: scheme.primary.withValues(alpha: 0.15),
          boundary: scheme.tertiary,
          cursor: scheme.error,
          background: scheme.surfaceContainerHighest,
          trimHandle: scheme.secondary,
          // Затемнение поверх волны: обрезаемые края видно, но они не спорят с
          // остающейся серединой.
          trimmedAway: scheme.scrim.withValues(alpha: 0.45),
        ),
      ],
    );
  }
}
