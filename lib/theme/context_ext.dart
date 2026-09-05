import 'package:flutter/material.dart';

import 'package:shado/theme/tokens/app_colors.dart';
import 'package:shado/theme/tokens/app_dimens.dart';
import 'package:shado/theme/tokens/app_shadows.dart';

/// Access to design tokens and the current layout from any widget.
extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  double get _width => MediaQuery.sizeOf(this).width;

  bool get isMobile => _width < AppBreakpoints.tablet;
  bool get isTablet =>
      _width >= AppBreakpoints.tablet && _width < AppBreakpoints.desktop;
  bool get isDesktop => _width >= AppBreakpoints.desktop;

  /// Value for the current layout; a missing tier falls back to a smaller one.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Whether the user asked to reduce motion.
  bool get reduceMotion =>
      MediaQuery.disableAnimationsOf(this) ||
      MediaQuery.accessibleNavigationOf(this);

  /// Animation duration adjusted for [reduceMotion].
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}
