import 'package:flutter/widgets.dart';

/// Type scale for Shadowing.
///
/// Styles are intentionally color-agnostic: color comes from the theme's
/// text theme or from `context.colors` at the call site, so the same style
/// works in both light and dark.
///
/// Families must match the `family:` names declared in pubspec.yaml.
abstract final class AppText {
  static const String display = 'Sora';
  static const String textFamily = 'PlusJakartaSans';
  static const String mono = 'JetBrainsMono';

  static const TextStyle displayLg = TextStyle(
    fontFamily: display,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: display,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: display,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: textFamily,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontFamily: textFamily,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontFamily: textFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: textFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Timecodes, durations, playback speed — anything numeric in the editor.
  static const TextStyle monoTime = TextStyle(
    fontFamily: mono,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
}
