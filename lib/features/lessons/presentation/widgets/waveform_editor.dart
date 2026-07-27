import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/waveform_peaks.dart';

/// Волна всего аудио с перетаскиваемыми метками границ.
///
/// Границы общие: для `N` кусков приходит `N + 1` значение, крайние из них
/// прибиты к краям аудио, а перетаскивать можно `N - 1` внутреннюю метку.
class WaveformEditor extends StatefulWidget {
  const WaveformEditor({
    super.key,
    required this.peaks,
    required this.durationMs,
    required this.boundaries,
    required this.positionMs,
    required this.onBoundariesChanged,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 140,
  });

  final WaveformPeaks peaks;
  final int durationMs;
  final List<int> boundaries;
  final int positionMs;
  final ValueChanged<List<int>> onBoundariesChanged;
  final int? activeSegmentIndex;
  final bool showCursor;
  final double height;

  @override
  State<WaveformEditor> createState() => _WaveformEditorState();
}

class _WaveformEditorState extends State<WaveformEditor> {
  /// Радиус захвата метки пальцем.
  static const double _touchSlop = 24;

  late List<int> _boundaries = List<int>.of(widget.boundaries);
  int? _draggedIndex;

  @override
  void didUpdateWidget(WaveformEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пока метку тащат, внешние обновления не перетирают локальное состояние.
    if (_draggedIndex == null && widget.boundaries != oldWidget.boundaries) {
      _boundaries = List<int>.of(widget.boundaries);
    }
  }

  double _msToX(int ms, double width) =>
      widget.durationMs <= 0 ? 0 : ms / widget.durationMs * width;

  int _xToMs(double x, double width) =>
      width <= 0 ? 0 : (x / width * widget.durationMs).round();

  void _onPanStart(DragStartDetails details, double width) {
    final x = details.localPosition.dx;
    var nearest = -1;
    var nearestDistance = double.infinity;
    for (var i = 1; i < _boundaries.length - 1; i++) {
      final distance = (_msToX(_boundaries[i], width) - x).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = i;
      }
    }
    if (nearest > 0 && nearestDistance <= _touchSlop) {
      setState(() => _draggedIndex = nearest);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    final index = _draggedIndex;
    if (index == null) return;
    final lowerLimit = _boundaries[index - 1] + kMinSegmentGapMs;
    final upperLimit = _boundaries[index + 1] - kMinSegmentGapMs;
    if (upperLimit <= lowerLimit) return;
    final ms = _xToMs(details.localPosition.dx, width);
    setState(() {
      _boundaries[index] = ms.clamp(lowerLimit, upperLimit);
    });
  }

  void _onPanEnd() {
    if (_draggedIndex == null) return;
    setState(() => _draggedIndex = null);
    widget.onBoundariesChanged(List<int>.unmodifiable(_boundaries));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<WaveformColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onPanStart(details, width),
          onPanUpdate: (details) => _onPanUpdate(details, width),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: _onPanEnd,
          child: CustomPaint(
            size: Size(width, widget.height),
            painter: _WaveformPainter(
              peaks: widget.peaks,
              durationMs: widget.durationMs,
              boundaries: _boundaries,
              activeSegmentIndex: widget.activeSegmentIndex,
              positionMs: widget.showCursor ? widget.positionMs : null,
              draggedIndex: _draggedIndex,
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.peaks,
    required this.durationMs,
    required this.boundaries,
    required this.activeSegmentIndex,
    required this.positionMs,
    required this.draggedIndex,
    required this.colors,
  });

  final WaveformPeaks peaks;
  final int durationMs;
  final List<int> boundaries;
  final int? activeSegmentIndex;
  final int? positionMs;
  final int? draggedIndex;
  final WaveformColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = colors.background;
    canvas.drawRect(Offset.zero & size, background);
    if (durationMs <= 0) return;

    final centerY = size.height / 2;
    final halfHeight = size.height / 2 - 4;

    _paintActiveSegment(canvas, size);
    _paintWave(canvas, size, centerY, halfHeight);
    _paintBoundaries(canvas, size);
    _paintCursor(canvas, size);
  }

  double _msToX(int ms, double width) => ms / durationMs * width;

  void _paintActiveSegment(Canvas canvas, Size size) {
    final index = activeSegmentIndex;
    if (index == null || index + 1 >= boundaries.length) return;
    final from = _msToX(boundaries[index], size.width);
    final to = _msToX(boundaries[index + 1], size.width);
    canvas.drawRect(
      Rect.fromLTRB(from, 0, to, size.height),
      Paint()..color = colors.activeSegment,
    );
  }

  void _paintWave(Canvas canvas, Size size, double centerY, double halfHeight) {
    if (peaks.isEmpty) return;
    final paint = Paint()
      ..color = colors.wave
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final columns = size.width.floor();
    for (var column = 0; column < columns; column++) {
      final bucket = math.min(
        peaks.length - 1,
        column * peaks.length ~/ math.max(1, columns),
      );
      final top = centerY + peaks.maxima[bucket] * -halfHeight;
      final bottom = centerY + peaks.minima[bucket].abs() * halfHeight;
      final x = column + 0.5;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  void _paintBoundaries(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = colors.boundary.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final handlePaint = Paint()
      ..color = colors.boundary
      ..strokeWidth = 2;

    for (var i = 0; i < boundaries.length; i++) {
      final x = _msToX(boundaries[i], size.width).clamp(0.5, size.width - 0.5);
      final isInner = i > 0 && i < boundaries.length - 1;
      if (!isInner) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), edgePaint);
        continue;
      }
      final isDragged = i == draggedIndex;
      final paint = isDragged
          ? (Paint()
              ..color = colors.boundary
              ..strokeWidth = 3)
          : handlePaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      // Ручка-кружок сверху, чтобы метку было за что взять.
      canvas.drawCircle(
        Offset(x, 8),
        isDragged ? 8 : 6,
        Paint()..color = colors.boundary,
      );
    }
  }

  void _paintCursor(Canvas canvas, Size size) {
    final position = positionMs;
    if (position == null) return;
    final x = _msToX(position, size.width).clamp(0.0, size.width);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = colors.cursor
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.durationMs != durationMs ||
        oldDelegate.positionMs != positionMs ||
        oldDelegate.activeSegmentIndex != activeSegmentIndex ||
        oldDelegate.draggedIndex != draggedIndex ||
        !_sameBoundaries(oldDelegate.boundaries, boundaries);
  }

  bool _sameBoundaries(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
