import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Фирменная поверхность из макета: градиент от нажатого primary к accent.
/// На ней живут логотип, шапка карточки и брендовая панель десктопа.
///
/// [decorated] добавляет полупрозрачный круг в правом нижнем углу — то самое
/// пятно, которое в макете рисует `::after`.
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

  /// Диаметр декоративного пятна и то, насколько оно уходит за край.
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
