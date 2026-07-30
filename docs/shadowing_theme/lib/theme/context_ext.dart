import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_dimens.dart';
import 'tokens/app_shadows.dart';

/// Ergonomic access to design tokens and responsive state from any widget.
///
/// ```dart
/// Container(
///   color: context.colors.surface,
///   boxShadow: context.shadows.e1,
/// );
/// final pad = context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);
/// ```
extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  double get _width => MediaQuery.sizeOf(this).width;

  bool get isMobile => _width < AppBreakpoints.tablet;
  bool get isTablet => _width >= AppBreakpoints.tablet && _width < AppBreakpoints.desktop;
  bool get isDesktop => _width >= AppBreakpoints.desktop;

  /// Pick a value per breakpoint. `mobile` is required; larger tiers fall
  /// back to the next smaller one when omitted.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}
