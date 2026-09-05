import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Keyboard focus ring; painted as a shadow, it takes no layout space.
class AppFocusRing extends StatelessWidget {
  const AppFocusRing({
    super.key,
    required this.visible,
    required this.borderRadius,
    required this.child,
  });

  final bool visible;
  final BorderRadius borderRadius;
  final Widget child;

  /// Whether focus arrived from the keyboard rather than a tap.
  static bool get isKeyboardFocus =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: context.motion(AppDurations.fast),
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: visible
            ? [
                BoxShadow(
                  color: context.colors.primary.withValues(
                    alpha: AppOpacities.focusRing,
                  ),
                  spreadRadius: AppSizes.focusRing,
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}
