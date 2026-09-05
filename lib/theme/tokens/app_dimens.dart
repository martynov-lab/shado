import 'package:flutter/widgets.dart';

/// 4pt spacing scale for padding, gaps and margins.
abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

/// Corner radii: raw values plus ready-made [BorderRadius] constants.
abstract final class AppRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 999;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));
}

/// Layout breakpoints: phone, tablet, desktop.
abstract final class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Maximum content width on wide screens.
  static const double maxContent = 1040;
}

/// Sizes of controls and the elements inside them.
abstract final class AppSizes {
  /// Minimum touch target.
  static const double minTouchTarget = 48;

  // Interactive control heights for the sm / md / lg sizes.
  static const double controlSm = 36;
  static const double controlMd = 44;
  static const double controlLg = 52;

  // Icons.
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  // Borders.
  static const double borderThin = 1;
  static const double borderThick = 2;

  /// Keyboard focus ring thickness.
  static const double focusRing = 3;

  // Form elements.
  static const double checkbox = 22;
  static const double radio = 22;
  static const double radioDot = 10;
  static const double switchWidth = 48;
  static const double switchHeight = 28;
  static const double switchThumb = 22;
  static const double sliderTrack = 6;
  static const double sliderThumb = 20;

  /// Lesson cover in a list row.
  static const double cover = 48;

  /// Spinner diameter inside a button.
  static const double spinner = 18;
  static const double spinnerStroke = 2;

  // Bottom sheet handle.
  static const double sheetHandleWidth = 40;
  static const double sheetHandleHeight = 4;

  /// Maximum width of a popup menu and a toast.
  static const double overlayMaxWidth = 420;
}

/// Opacities for overlays and disabled states.
abstract final class AppOpacities {
  /// The whole disabled control.
  static const double disabled = 0.45;

  /// Hover and press highlight.
  static const double hover = 0.08;
  static const double press = 0.14;

  /// The same over a filled primary surface.
  static const double hoverOnPrimary = 0.10;
  static const double pressOnPrimary = 0.18;

  /// Focus ring and the scrim under overlays.
  static const double focusRing = 0.55;
  static const double scrim = 0.45;
}
