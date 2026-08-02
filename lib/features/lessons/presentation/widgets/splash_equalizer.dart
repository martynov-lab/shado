import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Живой эквалайзер на сплеше: столбики «дышат» фирменным градиентом, пока идёт
/// инициализация. Контроллером анимации распоряжается сам — экрану о нём знать
/// незачем. При системном «уменьшить движение» показывает статичный кадр.
class SplashEqualizer extends StatefulWidget {
  const SplashEqualizer({super.key, this.size = const Size(74, 34)});

  final Size size;

  @override
  State<SplashEqualizer> createState() => _SplashEqualizerState();
}

class _SplashEqualizerState extends State<SplashEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery с флагом доступности виден только отсюда; повтор включаем
    // здесь же, чтобы build оставался чистой разметкой.
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) =>
            CustomPaint(painter: _EqualizerPainter(_controller.value)),
      ),
    );
  }
}

/// Столбики эквалайзера, залитые брендовым градиентом. [t] — фаза 0..1.
class _EqualizerPainter extends CustomPainter {
  _EqualizerPainter(this.t);

  final double t;

  static const int _barCount = 7;
  static const double _barWidth = 5;
  static const double _minBarHeight = 8;
  static const Radius _barRadius = Radius.circular(3);

  @override
  void paint(Canvas canvas, Size size) {
    final gap = (size.width - _barCount * _barWidth) / (_barCount - 1);
    final paint = Paint()
      ..shader = AppBrand.signGradient.createShader(Offset.zero & size);

    for (var i = 0; i < _barCount; i++) {
      // Сдвиг фазы по столбику даёт эффект бегущей волны.
      final phase = t * 2 * math.pi + i * 0.9;
      final amplitude = (0.5 + 0.5 * math.sin(phase)).abs();
      final height = _minBarHeight + (size.height - _minBarHeight) * amplitude;
      final x = i * (_barWidth + gap);
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, _barWidth, height),
        _barRadius,
      );
      canvas.drawRRect(bar, paint);
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter oldDelegate) => oldDelegate.t != t;
}
