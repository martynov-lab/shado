import 'package:flutter/widgets.dart';

/// Brand surface colors for the splash and the mark; independent of the theme.
abstract final class AppBrand {
  /// Dark brand background, shared with the native splash.
  static const Color surface = Color(0xFF100E18);

  /// Mark gradient: violet → magenta → pink.
  static const LinearGradient signGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFF), Color(0xFFA855F7), Color(0xFFFF7CA8)],
    stops: [0.0, 0.55, 1.0],
  );
}
