import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Brand surface on a gradient; [decorated] adds a decorative bubble.

class AuthBrandSurface extends StatelessWidget {
  const AuthBrandSurface({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    this.decorated = false,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final bool decorated;

  /// Diameter of the decorative bubble and how far it overflows.
  static const double _bubbleSize = 220;
  static const double _bubbleOverflow = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryPress, colors.primary, colors.accent],
        ),
      ),
      child: Stack(
        children: [
          if (decorated)
            Positioned(
              right: -_bubbleOverflow,
              bottom: -_bubbleOverflow,
              child: Container(
                width: _bubbleSize,
                height: _bubbleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryOn.withValues(alpha: AppOpacities.hover),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
