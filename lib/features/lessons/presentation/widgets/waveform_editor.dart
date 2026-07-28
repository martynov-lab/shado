import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/duration_format.dart';
import '../../data/models/waveform_peaks.dart';

/// Волна всего аудио с перетаскиваемыми метками границ.
///
/// Границы общие: для `N` кусков приходит `N + 1` значение, крайние из них
/// прибиты к краям аудио, а перетаскивать можно `N - 1` внутреннюю метку.
///
/// Если задан [onSeek], на волне появляется ползунок воспроизведения: его
/// таскают за ручку внизу или переносят тапом по волне.
///
/// Управление устроено так, чтобы жест никогда не значил двух вещей сразу:
///
/// - ручки (кружок границы наверху, треугольник ползунка внизу) тащат саму
///   метку — взять её можно только за ручку;
/// - перетаскивание в любом другом месте двигает волну под окном; на
///   растянутой волне это единственный способ добраться до её остальной части;
/// - масштаб — щипок двумя пальцами или Ctrl + колесо мыши; растянутая волна
///   показывает лишь часть аудио, зато метку удаётся поставить точнее.
class WaveformEditor extends StatefulWidget {
  const WaveformEditor({
    super.key,
    required this.peaks,
    required this.durationMs,
    required this.boundaries,
    required this.positionMs,
    required this.onBoundariesChanged,
    this.onSeek,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 140,
    this.showSegmentNumbers = true,
  });

  final WaveformPeaks peaks;
  final int durationMs;
  final List<int> boundaries;

  /// Где стоит ползунок воспроизведения.
  final int positionMs;

  final ValueChanged<List<int>> onBoundariesChanged;

  /// Куда перенесли ползунок: тапом по волне или перетаскиванием его ручки.
  /// `null` — волна только для разметки, ползунок неподвижен.
  final ValueChanged<int>? onSeek;

  final int? activeSegmentIndex;
  final bool showCursor;
  final double height;

  /// Номера кусков на волне: помогают сопоставить куски текста с аудио.
  final bool showSegmentNumbers;

  @override
  State<WaveformEditor> createState() => _WaveformEditorState();
}

/// Высота полоски с временной шкалой сверху.
const double _rulerHeight = 14;

/// Кружок-ручка границы: центр под шкалой, у самого верха волны.
const double _boundaryHandleY = _rulerHeight + 8;
const double _boundaryHandleRadius = 6;

/// Треугольная ручка ползунка у нижнего края волны.
const double _playheadHandleHeight = 14;

class _WaveformEditorState extends State<WaveformEditor> {
  /// Радиус, в котором ручка считается взятой. Заметно больше самой ручки:
  /// палец толще кружка, но и не настолько, чтобы перехватывать перетаскивание
  /// волны из середины.
  static const double _handleGrabRadius = 22;

  /// Пределы растяжения: дальше 200× секунда занимает пол-экрана и точность
  /// упирается уже в сами пики, а не в масштаб.
  static const double _minZoom = 1;
  static const double _maxZoom = 200;

  /// Полоса у края окна, при заходе в которую волна едет сама.
  static const double _autoScrollZone = 28;
  static const double _autoScrollPixelsPerTick = 6;
  static const Duration _autoScrollTick = Duration(milliseconds: 16);

  late List<int> _boundaries = List<int>.of(widget.boundaries);
  int? _draggedIndex;

  /// Положение ползунка, пока его тащат: наружу оно уходит только по отпуске,
  /// чтобы не гонять плеер на каждом кадре.
  int? _draggedPlayheadMs;

  /// Во сколько раз волна шире окна.
  double _zoom = 1;

  /// Сдвиг окна по растянутой волне, в пикселях от её начала.
  double _offset = 0;

  double _viewportWidth = 0;
  double _zoomAtScaleStart = 1;
  double? _dragPointerX;
  Timer? _autoScrollTimer;

  @override
  void didUpdateWidget(WaveformEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пока метку тащат, внешние обновления не перетирают локальное состояние.
    if (_draggedIndex == null && widget.boundaries != oldWidget.boundaries) {
      _boundaries = List<int>.of(widget.boundaries);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  double get _contentWidth => _viewportWidth * _zoom;

  double get _maxOffset => math.max(0, _contentWidth - _viewportWidth);

  /// Экранная координата момента времени.
  double _msToX(int ms) => widget.durationMs <= 0
      ? 0
      : ms / widget.durationMs * _contentWidth - _offset;

  int _xToMs(double x) => _contentWidth <= 0
      ? 0
      : ((x + _offset) / _contentWidth * widget.durationMs).round();

  void _setOffset(double value) {
    final clamped = value.clamp(0.0, _maxOffset);
    if (clamped != _offset) setState(() => _offset = clamped);
  }

  /// Меняет масштаб, оставляя на месте момент времени под точкой [focalX].
  void _setZoom(double zoom, double focalX) {
    final next = zoom.clamp(_minZoom, _maxZoom);
    if (next == _zoom) return;
    final anchorMs = _xToMs(focalX);
    setState(() {
      _zoom = next;
      final anchorContentX = widget.durationMs <= 0
          ? 0.0
          : anchorMs / widget.durationMs * _contentWidth;
      _offset = (anchorContentX - focalX).clamp(0.0, _maxOffset);
    });
  }

  // --- Ввод ------------------------------------------------------------------

  /// Колесо мыши достаётся либо волне, либо прокрутке страницы под ней —
  /// решает [PointerSignalResolver], поэтому свои события мы регистрируем, а
  /// чужие не трогаем.
  void _onPointerSignal(PointerSignalEvent event) {
    final resolver = GestureBinding.instance.pointerSignalResolver;
    if (event is PointerScrollEvent) {
      final keys = HardwareKeyboard.instance;
      if (keys.isControlPressed || keys.isMetaPressed) {
        resolver.register(event, (resolved) {
          final scroll = resolved as PointerScrollEvent;
          _setZoom(
            _zoom * math.exp(-scroll.scrollDelta.dy / 300),
            scroll.localPosition.dx,
          );
        });
      } else if (_maxOffset > 0) {
        // Пока волна помещается целиком, прокручивать в ней нечего — колесо
        // отдаём форме, внутри которой она лежит.
        resolver.register(event, (resolved) {
          final scroll = resolved as PointerScrollEvent;
          // Вертикальное колесо тоже двигает волну: горизонтального у обычной
          // мыши нет.
          _setOffset(_offset + scroll.scrollDelta.dx + scroll.scrollDelta.dy);
        });
      }
    } else if (event is PointerScaleEvent) {
      // Щипок на трекпаде.
      resolver.register(event, (resolved) {
        final scale = resolved as PointerScaleEvent;
        _setZoom(_zoom * scale.scale, scale.localPosition.dx);
      });
    }
  }

  /// Ползунок виден только там, где им управляют.
  bool get _hasPlayhead => widget.onSeek != null && widget.showCursor;

  int get _playheadMs => _draggedPlayheadMs ?? widget.positionMs;

  bool get _isDragging => _draggedIndex != null || _draggedPlayheadMs != null;

  /// Центр кружка-ручки границы.
  Offset _boundaryHandleCenter(int index) =>
      Offset(_msToX(_boundaries[index]), _boundaryHandleY);

  /// Центр треугольной ручки ползунка.
  Offset get _playheadHandleCenter =>
      Offset(_msToX(_playheadMs), widget.height - _playheadHandleHeight / 2);

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtScaleStart = _zoom;
    if (details.pointerCount > 1) return;
    final point = details.localFocalPoint;

    var nearest = -1;
    var nearestDistance = double.infinity;
    for (var i = 1; i < _boundaries.length - 1; i++) {
      final distance = (_boundaryHandleCenter(i) - point).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = i;
      }
    }
    // Ручки ползунка и границы могут оказаться рядом — берём ту, что ближе.
    final playheadDistance = _hasPlayhead
        ? (_playheadHandleCenter - point).distance
        : double.infinity;

    if (playheadDistance <= _handleGrabRadius &&
        playheadDistance <= nearestDistance) {
      _dragPointerX = point.dx;
      setState(() => _draggedPlayheadMs = _playheadMs);
      return;
    }
    if (nearest > 0 && nearestDistance <= _handleGrabRadius) {
      setState(() => _draggedIndex = nearest);
      _dragPointerX = point.dx;
    }
    // Мимо ручек — перетаскивание уедет в панораму волны.
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      _setZoom(_zoomAtScaleStart * details.scale, details.localFocalPoint.dx);
      _setOffset(_offset - details.focalPointDelta.dx);
      return;
    }
    if (!_isDragging) {
      _setOffset(_offset - details.focalPointDelta.dx);
      return;
    }
    _dragPointerX = details.localFocalPoint.dx;
    _updateAutoScroll();
    _moveDragTarget();
  }

  /// Двигает то, что взяли: метку границы или ползунок.
  void _moveDragTarget() {
    if (_draggedPlayheadMs != null) {
      _moveDraggedPlayhead();
    } else {
      _moveDraggedBoundary();
    }
  }

  void _moveDraggedBoundary() {
    final index = _draggedIndex;
    final x = _dragPointerX;
    if (index == null || x == null) return;
    final lowerLimit = _boundaries[index - 1] + kMinSegmentGapMs;
    final upperLimit = _boundaries[index + 1] - kMinSegmentGapMs;
    if (upperLimit <= lowerLimit) return;
    final ms = _xToMs(x).clamp(lowerLimit, upperLimit);
    if (ms == _boundaries[index]) return;
    setState(() => _boundaries[index] = ms);
  }

  void _moveDraggedPlayhead() {
    final x = _dragPointerX;
    if (x == null) return;
    final ms = _xToMs(x).clamp(0, widget.durationMs);
    if (ms == _draggedPlayheadMs) return;
    setState(() => _draggedPlayheadMs = ms);
  }

  /// Тянет волну, пока метку держат у края окна: иначе на большом масштабе её
  /// не увести дальше видимого куска.
  void _updateAutoScroll() {
    final x = _dragPointerX;
    if (x == null || _maxOffset <= 0) {
      _stopAutoScroll();
      return;
    }
    final direction = x < _autoScrollZone
        ? -1
        : (x > _viewportWidth - _autoScrollZone ? 1 : 0);
    if (direction == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollTimer ??= Timer.periodic(_autoScrollTick, (_) {
      final pointerX = _dragPointerX;
      if (pointerX == null) {
        _stopAutoScroll();
        return;
      }
      final step = pointerX < _autoScrollZone
          ? -_autoScrollPixelsPerTick
          : (pointerX > _viewportWidth - _autoScrollZone
                ? _autoScrollPixelsPerTick
                : 0.0);
      if (step == 0 ||
          (step < 0 && _offset <= 0) ||
          (step > 0 && _offset >= _maxOffset)) {
        _stopAutoScroll();
        return;
      }
      _setOffset(_offset + step);
      _moveDragTarget();
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _stopAutoScroll();
    _dragPointerX = null;
    final playheadMs = _draggedPlayheadMs;
    if (playheadMs != null) {
      setState(() => _draggedPlayheadMs = null);
      widget.onSeek?.call(playheadMs);
      return;
    }
    if (_draggedIndex == null) return;
    setState(() => _draggedIndex = null);
    widget.onBoundariesChanged(List<int>.unmodifiable(_boundaries));
  }

  /// Тап по волне переносит ползунок — так до нужного места быстрее, чем
  /// тащить его через весь урок.
  void _onTapUp(TapUpDetails details) {
    final onSeek = widget.onSeek;
    if (onSeek == null) return;
    onSeek(_xToMs(details.localPosition.dx).clamp(0, widget.durationMs));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<WaveformColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ширина меняется на повороте экрана — окно должно остаться на месте.
        if (_viewportWidth != constraints.maxWidth) {
          _viewportWidth = constraints.maxWidth;
          _offset = _offset.clamp(0.0, _maxOffset);
        }
        return Listener(
          onPointerSignal: _onPointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onTapUp: widget.onSeek == null ? null : _onTapUp,
            child: CustomPaint(
              size: Size(_viewportWidth, widget.height),
              painter: _WaveformPainter(
                peaks: widget.peaks,
                durationMs: widget.durationMs,
                boundaries: _boundaries,
                activeSegmentIndex: widget.activeSegmentIndex,
                positionMs: widget.showCursor ? _playheadMs : null,
                isPlayheadDraggable: _hasPlayhead,
                isPlayheadDragged: _draggedPlayheadMs != null,
                draggedIndex: _draggedIndex,
                colors: colors,
                zoom: _zoom,
                offset: _offset,
                showSegmentNumbers: widget.showSegmentNumbers,
                textDirection: Directionality.of(context),
              ),
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
    required this.isPlayheadDraggable,
    required this.isPlayheadDragged,
    required this.draggedIndex,
    required this.colors,
    required this.zoom,
    required this.offset,
    required this.showSegmentNumbers,
    required this.textDirection,
  });

  final WaveformPeaks peaks;
  final int durationMs;
  final List<int> boundaries;
  final int? activeSegmentIndex;
  final int? positionMs;
  final bool isPlayheadDraggable;
  final bool isPlayheadDragged;
  final int? draggedIndex;
  final WaveformColors colors;
  final double zoom;
  final double offset;
  final bool showSegmentNumbers;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = colors.background;
    canvas.drawRect(Offset.zero & size, background);
    if (durationMs <= 0) return;

    final waveTop = _rulerHeight;
    final waveHeight = size.height - _rulerHeight;
    final centerY = waveTop + waveHeight / 2;
    final halfHeight = waveHeight / 2 - 4;

    _paintActiveSegment(canvas, size);
    _paintWave(canvas, size, centerY, halfHeight);
    _paintRuler(canvas, size);
    _paintBoundaries(canvas, size);
    _paintSegmentNumbers(canvas, size);
    _paintCursor(canvas, size);
    _paintScrollbar(canvas, size);
    _paintZoomLabel(canvas, size);
  }

  /// Ширина растянутой волны целиком; в окно шириной [viewportWidth] попадает
  /// её часть, начиная с [offset].
  double _contentWidth(double viewportWidth) => viewportWidth * zoom;

  double _msToX(int ms, double width) =>
      ms / durationMs * _contentWidth(width) - offset;

  int _xToMs(double x, double width) =>
      ((x + offset) / _contentWidth(width) * durationMs).round();

  void _paintActiveSegment(Canvas canvas, Size size) {
    final index = activeSegmentIndex;
    if (index == null || index + 1 >= boundaries.length) return;
    final from = _msToX(boundaries[index], size.width);
    final to = _msToX(boundaries[index + 1], size.width);
    if (to < 0 || from > size.width) return;
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
    // Рисуем только видимые столбики: на большом масштабе волна шире окна во
    // много раз, и проходить её целиком незачем.
    final columns = size.width.floor();
    final msPerColumn = durationMs / _contentWidth(size.width);
    for (var column = 0; column < columns; column++) {
      final ms = (column + offset) * msPerColumn;
      final bucket = (ms / durationMs * peaks.length).floor();
      if (bucket < 0 || bucket >= peaks.length) continue;
      final top = centerY + peaks.maxima[bucket] * -halfHeight;
      final bottom = centerY + peaks.minima[bucket].abs() * halfHeight;
      final x = column + 0.5;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  /// Засечки времени: на растянутой волне без них не понять, куда уехали.
  void _paintRuler(Canvas canvas, Size size) {
    final stepMs = _rulerStepMs(size.width);
    if (stepMs <= 0) return;
    final paint = Paint()
      ..color = colors.wave.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final fromMs = math.max(0, _xToMs(0, size.width));
    final toMs = math.min(durationMs, _xToMs(size.width, size.width));
    for (var ms = (fromMs ~/ stepMs) * stepMs; ms <= toMs; ms += stepMs) {
      final x = _msToX(ms, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, _rulerHeight), paint);
      _paintLabel(canvas, formatPosition(ms), Offset(x + 3, 1), colors.wave, 9);
    }
  }

  /// Круглый шаг засечек, при котором подписи не наезжают друг на друга.
  int _rulerStepMs(double width) {
    const candidates = <int>[
      100,
      200,
      500,
      1000,
      2000,
      5000,
      10000,
      15000,
      30000,
      60000,
      120000,
      300000,
      600000,
    ];
    final contentWidth = _contentWidth(width);
    if (contentWidth <= 0) return 0;
    final minStepMs = 64 * durationMs / contentWidth;
    for (final candidate in candidates) {
      if (candidate >= minStepMs) return candidate;
    }
    return candidates.last;
  }

  void _paintBoundaries(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = colors.boundary.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final handlePaint = Paint()
      ..color = colors.boundary
      ..strokeWidth = 2;

    for (var i = 0; i < boundaries.length; i++) {
      final isInner = i > 0 && i < boundaries.length - 1;
      final rawX = _msToX(boundaries[i], size.width);
      if (isInner && (rawX < -8 || rawX > size.width + 8)) continue;
      final x = rawX.clamp(0.5, size.width - 0.5);
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
      // Кружок сверху — единственное место, за которое метку берут.
      canvas.drawCircle(
        Offset(x, _boundaryHandleY),
        isDragged ? _boundaryHandleRadius + 2 : _boundaryHandleRadius,
        Paint()..color = colors.boundary,
      );
      if (isDragged) {
        // Пока метку тащат, показываем точное время под пальцем.
        _paintLabel(
          canvas,
          formatPosition(boundaries[i]),
          Offset(x + 10, _rulerHeight + 2),
          colors.boundary,
          11,
        );
      }
    }
  }

  void _paintSegmentNumbers(Canvas canvas, Size size) {
    if (!showSegmentNumbers || boundaries.length < 2) return;
    for (var i = 0; i < boundaries.length - 1; i++) {
      final from = _msToX(boundaries[i], size.width);
      final to = _msToX(boundaries[i + 1], size.width);
      if (to < 0 || from > size.width) continue;
      // Номер держится в видимой части куска, а не уезжает вместе с началом.
      final left = math.max(from, 0.0);
      final right = math.min(to, size.width);
      if (right - left < 16) continue;
      _paintLabel(
        canvas,
        '${i + 1}',
        Offset(left + 4, size.height - 20),
        colors.boundary.withValues(alpha: 0.8),
        11,
      );
    }
  }

  void _paintCursor(Canvas canvas, Size size) {
    final position = positionMs;
    if (position == null) return;
    final x = _msToX(position, size.width);
    if (x < -12 || x > size.width + 12) return;
    final paint = Paint()
      ..color = colors.cursor
      ..strokeWidth = isPlayheadDragged ? 3 : 2;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    if (!isPlayheadDraggable) return;

    // Ручка внизу — треугольник, чтобы ползунок не путался с круглыми
    // ручками границ наверху.
    final width = isPlayheadDragged ? 13.0 : 10.0;
    final baseY = size.height - _playheadHandleHeight;
    canvas.drawPath(
      Path()
        ..moveTo(x - width / 2, size.height)
        ..lineTo(x + width / 2, size.height)
        ..lineTo(x, baseY)
        ..close(),
      Paint()..color = colors.cursor,
    );
    if (isPlayheadDragged) {
      _paintLabel(
        canvas,
        formatPosition(position),
        Offset(x + 10, baseY - 12),
        colors.cursor,
        11,
      );
    }
  }

  /// Текущий масштаб: кнопок нет, а понимать, насколько волна растянута,
  /// нужно. Пока она помещается целиком, подпись не нужна.
  void _paintZoomLabel(Canvas canvas, Size size) {
    if (zoom <= 1.05) return;
    final text = '${zoom < 10 ? zoom.toStringAsFixed(1) : zoom.round()}×';
    final painter = _layoutLabel(text, colors.wave, 10);
    painter.paint(
      canvas,
      Offset(size.width - painter.width - 6, size.height - painter.height - 8),
    );
  }

  /// Индикатор видимого окна: показывает, какая часть аудио сейчас на экране.
  void _paintScrollbar(Canvas canvas, Size size) {
    final contentWidth = _contentWidth(size.width);
    if (zoom <= 1 || contentWidth <= 0) return;
    // Ползунок — то же окно, только сжатое до ширины виджета.
    final thumbWidth = math.max(24.0, size.width / zoom);
    final left = (offset / contentWidth) * size.width;
    final rect = Rect.fromLTWH(
      left.clamp(0.0, size.width - thumbWidth),
      size.height - 3,
      thumbWidth,
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = colors.wave.withValues(alpha: 0.5),
    );
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double fontSize,
  ) {
    _layoutLabel(text, color, fontSize).paint(canvas, at);
  }

  TextPainter _layoutLabel(String text, Color color, double fontSize) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: textDirection,
    )..layout();
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.durationMs != durationMs ||
        oldDelegate.positionMs != positionMs ||
        oldDelegate.isPlayheadDraggable != isPlayheadDraggable ||
        oldDelegate.isPlayheadDragged != isPlayheadDragged ||
        oldDelegate.activeSegmentIndex != activeSegmentIndex ||
        oldDelegate.draggedIndex != draggedIndex ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.showSegmentNumbers != showSegmentNumbers ||
        oldDelegate.colors != colors ||
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
