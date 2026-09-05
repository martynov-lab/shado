import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// App mark on the splash: a gradient tile with a centered wave.
class SplashBrandMark extends StatelessWidget {
  const SplashBrandMark({super.key, this.size = 104});

  /// Tile side; defaults to the splash mark size.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppBrand.signGradient,
        borderRadius: AppRadii.rXxl,
        // The glow under the tile is part of the logo, not a token shadow.
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.primary.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: CustomPaint(painter: _WaveMarkPainter(AppColors.dark.primaryOn)),
      ),
    );
  }
}

/// Wave mark: a polyline on a 24×24 grid stroked with [color].
class _WaveMarkPainter extends CustomPainter {
  const _WaveMarkPainter(this.color);

  final Color color;

  /// Polyline vertices on a 24×24 grid — logo geometry, not layout tokens.
  static const List<Offset> _points = [
    Offset(3, 12),
    Offset(5, 12),
    Offset(7, 6),
    Offset(10, 21),
    Offset(13, 3),
    Offset(16, 15),
    Offset(18, 12),
    Offset(21, 12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(_points.first.dx * unit, _points.first.dy * unit);
    for (final point in _points.skip(1)) {
      path.lineTo(point.dx * unit, point.dy * unit);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveMarkPainter oldDelegate) => oldDelegate.color != color;
}
