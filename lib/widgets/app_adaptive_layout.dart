import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Builds a layout by window width; a missing variant falls back to a
/// smaller one.
class AppAdaptiveLayout extends StatelessWidget {
  const AppAdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Phone (width < [AppBreakpoints.tablet]) — the base layout.
  final WidgetBuilder mobile;

  /// Tablet ([AppBreakpoints.tablet]..[AppBreakpoints.desktop)).
  final WidgetBuilder? tablet;

  /// Desktop and web (width ≥ [AppBreakpoints.desktop]).
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return (desktop ?? tablet ?? mobile)(context);
    if (context.isTablet) return (tablet ?? mobile)(context);
    return mobile(context);
  }
}
