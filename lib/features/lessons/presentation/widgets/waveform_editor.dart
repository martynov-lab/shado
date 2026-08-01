import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/duration_format.dart';
import '../../data/models/waveform_peaks.dart';
import '../../domain/entities/audio_trim.dart';

/// Какую метку обрезки сейчас тащат.
enum TrimEdge { start, end }

/// Волна аудио с перетаскиваемыми метками границ.
///
/// Времена везде абсолютные — миллисекунды от начала файла. В окно попадает
/// отрезок [view]: после обрезки это уже не весь файл, а только оставленный
/// кусок. Пики [peaks] построены ровно по [view], поэтому у обрезанной дорожки
/// разрешение волны не падает вместе с её длиной.
///
/// Границы кусков общие: для `N` кусков приходит `N + 1` значение, крайние из
/// них прибиты к краям [view], а перетаскивать можно `N - 1` внутреннюю метку.
///
/// Если задан [onSeek], на волне появляется ползунок воспроизведения: его
/// таскают за ручку внизу или переносят тапом по волне.
///
/// Заданный [trim] включает режим обрезки: на волне появляются две метки со
/// стрелочками, всё за ними затемняется, а метки границ кусков замирают —
/// сначала надо решить, что оставить.
///
/// Управление устроено так, чтобы жест никогда не значил двух вещей сразу:
///
/// - ручки (кружок границы наверху, стрелка обрезки посередине, треугольник
///   ползунка внизу) тащат саму метку — взять её можно только за ручку;
/// - перетаскивание в любом другом месте двигает волну под окном; на
///   растянутой волне это единственный способ добраться до её остальной части;
/// - масштаб — щипок двумя пальцами или Ctrl + колесо мыши; растянутая волна
///   показывает лишь часть аудио, зато метку удаётся поставить точнее.
class WaveformEditor extends StatefulWidget {
  const WaveformEditor({
    super.key,
    required this.peaks,
    required this.view,
    required this.boundaries,
    required this.positionMs,
    required this.onBoundariesChanged,
    this.onSeek,
    this.trim,
    this.onTrimChanged,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 140,
    this.showSegmentNumbers = true,
  });

  /// Пики видимого отрезка: [peaks] разложены ровно по [view].
  final WaveformPeaks peaks;

  /// Отрезок файла, попадающий в окно.
  final AudioTrim view;

  /// Границы кусков в миллисекундах файла.
  final List<int> boundaries;

  /// Где стоит ползунок воспроизведения, в миллисекундах файла.
  final int positionMs;

  final ValueChanged<List<int>> onBoundariesChanged;

  /// Куда перенесли ползунок: тапом по волне или перетаскиванием его ручки.
  /// `null` — волна только для разметки, ползунок неподвижен.
  final ValueChanged<int>? onSeek;

  /// Отрезок, который останется после обрезки. `null` — обрезка не идёт.
  final AudioTrim? trim;

  final ValueChanged<AudioTrim>? onTrimChanged;

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

/// Стрелка обрезки: язычок с треугольником посередине волны — между ручками
/// границ сверху и ручкой ползунка снизу.
const double _trimHandleWidth = 15;
const double _trimHandleHeight = 30;

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

  /// Обрезка, пока её метку тащат: наружу она уходит только по отпуске.
  late AudioTrim? _trim = widget.trim;
  TrimEdge? _draggedTrimEdge;

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
    if (_draggedTrimEdge == null && widget.trim != oldWidget.trim) {
      _trim = widget.trim;
    }
    // Обрезку применили или отменили — окно поехало, привязка к нему тоже.
    if (widget.view != oldWidget.view) {
      _zoom = 1;
      _offset = 0;
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  AudioTrim get _view => widget.view;

  double get _contentWidth => _viewportWidth * _zoom;

  double get _maxOffset => math.max(0, _contentWidth - _viewportWidth);

  /// Экранная координата момента времени.
  double _msToX(int ms) => _view.isEmpty
      ? 0
      : (ms - _view.startMs) / _view.durationMs * _contentWidth - _offset;

  int _xToMs(double x) => _contentWidth <= 0
      ? _view.startMs
      : _view.startMs +
            ((x + _offset) / _contentWidth * _view.durationMs).round();

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
      final anchorContentX = _view.isEmpty
          ? 0.0
          : (anchorMs - _view.startMs) / _view.durationMs * _contentWidth;
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

  /// Пока идёт обрезка, метки границ кусков заморожены: они всё равно поедут,
  /// когда обрезку применят.
  bool get _isTrimming => _trim != null;

  int get _playheadMs => _draggedPlayheadMs ?? widget.positionMs;

  bool get _isDragging =>
      _draggedIndex != null ||
      _draggedPlayheadMs != null ||
      _draggedTrimEdge != null;

  /// Центр кружка-ручки границы.
  Offset _boundaryHandleCenter(int index) =>
      Offset(_msToX(_boundaries[index]), _boundaryHandleY);

  /// Центр треугольной ручки ползунка.
  Offset get _playheadHandleCenter =>
      Offset(_msToX(_playheadMs), widget.height - _playheadHandleHeight / 2);

  /// Центр язычка метки обрезки: он лежит внутри остающегося куска.
  Offset _trimHandleCenter(TrimEdge edge) {
    final trim = _trim!;
    final x = _msToX(edge == TrimEdge.start ? trim.startMs : trim.endMs);
    final shift = edge == TrimEdge.start
        ? _trimHandleWidth / 2
        : -_trimHandleWidth / 2;
    return Offset(x + shift, _waveCenterY);
  }

  double get _waveCenterY => _rulerHeight + (widget.height - _rulerHeight) / 2;

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtScaleStart = _zoom;
    if (details.pointerCount > 1) return;
    final point = details.localFocalPoint;

    var nearest = -1;
    var nearestDistance = double.infinity;
    if (!_isTrimming) {
      for (var i = 1; i < _boundaries.length - 1; i++) {
        final distance = (_boundaryHandleCenter(i) - point).distance;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = i;
        }
      }
    }

    // Ручки могут оказаться рядом друг с другом — берём ту, что ближе.
    TrimEdge? nearestEdge;
    var nearestEdgeDistance = double.infinity;
    if (_isTrimming) {
      for (final edge in TrimEdge.values) {
        final distance = (_trimHandleCenter(edge) - point).distance;
        if (distance < nearestEdgeDistance) {
          nearestEdgeDistance = distance;
          nearestEdge = edge;
        }
      }
    }
    final playheadDistance = _hasPlayhead
        ? (_playheadHandleCenter - point).distance
        : double.infinity;

    if (nearestEdge != null &&
        nearestEdgeDistance <= _handleGrabRadius &&
        nearestEdgeDistance <= playheadDistance) {
      _dragPointerX = point.dx;
      setState(() => _draggedTrimEdge = nearestEdge);
      return;
    }
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

  /// Двигает то, что взяли: метку обрезки, метку границы или ползунок.
  void _moveDragTarget() {
    if (_draggedTrimEdge != null) {
      _moveDraggedTrimEdge();
    } else if (_draggedPlayheadMs != null) {
      _moveDraggedPlayhead();
    } else {
      _moveDraggedBoundary();
    }
  }

  void _moveDraggedTrimEdge() {
    final edge = _draggedTrimEdge;
    final trim = _trim;
    final x = _dragPointerX;
    if (edge == null || trim == null || x == null) return;
    final ms = _xToMs(x);
    final AudioTrim next;
    if (edge == TrimEdge.start) {
      final upperLimit = math.max(_view.startMs, trim.endMs - kMinTrimMs);
      next = AudioTrim(
        startMs: ms.clamp(_view.startMs, upperLimit),
        endMs: trim.endMs,
      );
    } else {
      final lowerLimit = math.min(_view.endMs, trim.startMs + kMinTrimMs);
      next = AudioTrim(
        startMs: trim.startMs,
        endMs: ms.clamp(lowerLimit, _view.endMs),
      );
    }
    if (next == trim) return;
    setState(() => _trim = next);
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
    final ms = _view.clampMs(_xToMs(x));
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
    if (_draggedTrimEdge != null) {
      final trim = _trim;
      setState(() => _draggedTrimEdge = null);
      if (trim != null) widget.onTrimChanged?.call(trim);
      return;
    }
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
    onSeek(_view.clampMs(_xToMs(details.localPosition.dx)));
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
                view: _view,
                boundaries: _boundaries,
                activeSegmentIndex: _isTrimming
                    ? null
                    : widget.activeSegmentIndex,
                positionMs: widget.showCursor ? _playheadMs : null,
                isPlayheadDraggable: _hasPlayhead,
                isPlayheadDragged: _draggedPlayheadMs != null,
                draggedIndex: _draggedIndex,
                trim: _trim,
                draggedTrimEdge: _draggedTrimEdge,
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
    required this.view,
    required this.boundaries,
    required this.activeSegmentIndex,
    required this.positionMs,
    required this.isPlayheadDraggable,
    required this.isPlayheadDragged,
    required this.draggedIndex,
    required this.trim,
    required this.draggedTrimEdge,
    required this.colors,
    required this.zoom,
    required this.offset,
    required this.showSegmentNumbers,
    required this.textDirection,
  });

  final WaveformPeaks peaks;
  final AudioTrim view;
  final List<int> boundaries;
  final int? activeSegmentIndex;
  final int? positionMs;
  final bool isPlayheadDraggable;
  final bool isPlayheadDragged;
  final int? draggedIndex;
  final AudioTrim? trim;
  final TrimEdge? draggedTrimEdge;
  final WaveformColors colors;
  final double zoom;
  final double offset;
  final bool showSegmentNumbers;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = colors.background;
    canvas.drawRect(Offset.zero & size, background);
    if (view.isEmpty) return;

    final waveTop = _rulerHeight;
    final waveHeight = size.height - _rulerHeight;
    final centerY = waveTop + waveHeight / 2;
    final halfHeight = waveHeight / 2 - 4;

    _paintActiveSegment(canvas, size);
    _paintWave(canvas, size, centerY, halfHeight);
    _paintRuler(canvas, size);
    _paintBoundaries(canvas, size);
    _paintSegmentNumbers(canvas, size);
    _paintTrim(canvas, size, centerY);
    _paintCursor(canvas, size);
    _paintScrollbar(canvas, size);
    _paintZoomLabel(canvas, size);
  }

  /// Ширина растянутой волны целиком; в окно шириной [viewportWidth] попадает
  /// её часть, начиная с [offset].
  double _contentWidth(double viewportWidth) => viewportWidth * zoom;

  double _msToX(int ms, double width) =>
      (ms - view.startMs) / view.durationMs * _contentWidth(width) - offset;

  int _xToMs(double x, double width) =>
      view.startMs +
      ((x + offset) / _contentWidth(width) * view.durationMs).round();

  /// Время, которое видит пользователь: от левого края видимого куска, а не от
  /// начала файла — после обрезки урок начинается с нуля.
  int _displayMs(int ms) => ms - view.startMs;

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
    for (var column = 0; column < columns; column++) {
      final ms = _xToMs(column.toDouble(), size.width);
      final bucket = ((ms - view.startMs) / view.durationMs * peaks.length)
          .floor();
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
    final fromMs = math.max(view.startMs, _xToMs(0, size.width));
    final toMs = math.min(view.endMs, _xToMs(size.width, size.width));
    // Шаг отсчитываем от левого края окна: подписи должны идти круглыми
    // числами того времени, которое видит пользователь.
    final firstStep = (_displayMs(fromMs) ~/ stepMs) * stepMs;
    for (var shown = firstStep; shown <= _displayMs(toMs); shown += stepMs) {
      final x = _msToX(view.startMs + shown, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, _rulerHeight), paint);
      _paintLabel(
        canvas,
        formatPosition(shown),
        Offset(x + 3, 1),
        colors.wave,
        9,
      );
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
    final minStepMs = 64 * view.durationMs / contentWidth;
    for (final candidate in candidates) {
      if (candidate >= minStepMs) return candidate;
    }
    return candidates.last;
  }

  void _paintBoundaries(Canvas canvas, Size size) {
    // Во время обрезки метки кусков не трогают — показываем их бледнее, чтобы
    // не путались с метками обрезки.
    final alpha = trim == null ? 1.0 : 0.35;
    final edgePaint = Paint()
      ..color = colors.boundary.withValues(alpha: 0.4 * alpha)
      ..strokeWidth = 1;
    final handlePaint = Paint()
      ..color = colors.boundary.withValues(alpha: alpha)
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
        Paint()..color = colors.boundary.withValues(alpha: alpha),
      );
      if (isDragged) {
        // Пока метку тащат, показываем точное время под пальцем.
        _paintLabel(
          canvas,
          formatPosition(_displayMs(boundaries[i])),
          Offset(x + 10, _rulerHeight + 2),
          colors.boundary,
          11,
        );
      }
    }
  }

  void _paintSegmentNumbers(Canvas canvas, Size size) {
    if (!showSegmentNumbers || boundaries.length < 2 || trim != null) return;
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

  /// Обрезка: края за метками темнеют, сами метки — язычки со стрелочками,
  /// смотрящими внутрь того, что останется.
  void _paintTrim(Canvas canvas, Size size, double centerY) {
    final range = trim;
    if (range == null) return;
    final left = _msToX(range.startMs, size.width);
    final right = _msToX(range.endMs, size.width);
    final scrim = Paint()..color = colors.trimmedAway;
    if (left > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, math.min(left, size.width), size.height),
        scrim,
      );
    }
    if (right < size.width) {
      canvas.drawRect(
        Rect.fromLTRB(math.max(right, 0), 0, size.width, size.height),
        scrim,
      );
    }
    _paintTrimHandle(canvas, size, centerY, TrimEdge.start, left);
    _paintTrimHandle(canvas, size, centerY, TrimEdge.end, right);
  }

  void _paintTrimHandle(
    Canvas canvas,
    Size size,
    double centerY,
    TrimEdge edge,
    double x,
  ) {
    if (x < -_trimHandleWidth || x > size.width + _trimHandleWidth) return;
    final isDragged = edge == draggedTrimEdge;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = colors.trimHandle
        ..strokeWidth = isDragged ? 3 : 2,
    );

    // Язычок стоит на остающейся стороне: слева от левой метки и справа от
    // правой всё равно обрежут.
    final isStart = edge == TrimEdge.start;
    final width = isDragged ? _trimHandleWidth + 2 : _trimHandleWidth;
    final height = isDragged ? _trimHandleHeight + 4 : _trimHandleHeight;
    final rect = Rect.fromLTWH(
      isStart ? x : x - width,
      centerY - height / 2,
      width,
      height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = colors.trimHandle,
    );

    // Стрелочка внутрь: показывает, в какую сторону метку тащат, чтобы
    // отрезать больше.
    const arrow = 5.0;
    final tipX = isStart ? rect.right - 4 : rect.left + 4;
    final baseX = isStart ? rect.left + 4 : rect.right - 4;
    canvas.drawPath(
      Path()
        ..moveTo(baseX, centerY - arrow)
        ..lineTo(baseX, centerY + arrow)
        ..lineTo(tipX, centerY)
        ..close(),
      Paint()..color = colors.background,
    );

    if (!isDragged) return;
    final label = formatPosition(
      _displayMs(isStart ? trim!.startMs : trim!.endMs),
    );
    final painter = _layoutLabel(label, colors.trimHandle, 11);
    painter.paint(
      canvas,
      Offset(
        isStart ? x + width + 4 : x - width - 4 - painter.width,
        centerY - height / 2 - painter.height - 4,
      ),
    );
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
        formatPosition(_displayMs(position)),
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
        oldDelegate.view != view ||
        oldDelegate.positionMs != positionMs ||
        oldDelegate.isPlayheadDraggable != isPlayheadDraggable ||
        oldDelegate.isPlayheadDragged != isPlayheadDragged ||
        oldDelegate.activeSegmentIndex != activeSegmentIndex ||
        oldDelegate.draggedIndex != draggedIndex ||
        oldDelegate.trim != trim ||
        oldDelegate.draggedTrimEdge != draggedTrimEdge ||
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
