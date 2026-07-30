import 'package:flutter/animation.dart';

/// Animation durations. Keep transitions inside this scale so motion feels
/// like one system.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 120); // taps, hovers
  static const Duration base = Duration(milliseconds: 200); // most transitions
  static const Duration slow = Duration(milliseconds: 340); // theme swap, sheets

  /// Сколько всплывающее сообщение висит, прежде чем уйти само. Это не
  /// анимация, а время на прочтение, поэтому шкала другая.
  static const Duration toast = Duration(seconds: 4);
}

/// Easing curves.
abstract final class AppCurves {
  /// Standard emphasized easing — matches the style passport.
  static const Cubic standard = Cubic(0.2, 0, 0, 1);
}
