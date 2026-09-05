import 'package:flutter/animation.dart';

/// Animation durations.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 120); // taps, hovers
  static const Duration base = Duration(milliseconds: 200); // transitions
  static const Duration slow = Duration(
    milliseconds: 340,
  ); // theme swap, sheets

  /// How long a toast stays on screen.
  static const Duration toast = Duration(seconds: 4);
}

/// Easing curves.
abstract final class AppCurves {
  static const Cubic standard = Cubic(0.2, 0, 0, 1);
}
