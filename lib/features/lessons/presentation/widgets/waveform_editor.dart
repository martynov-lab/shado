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

/// Which trim handle is being dragged.
enum TrimEdge { start, end }

/// Audio waveform with boundary markers, trimming and a playhead; all times
/// are absolute file milliseconds.
class WaveformEditor extends StatefulWidget {
  const WaveformEditor({
    super.key,
    required this.peaks,
    required this.view,
    required this.boundaries,
    required this.positionMs,
    required this.onBoundariesChanged,
    this.onBoundaryRemoved,
    this.onSeek,
    this.trim,
    this.onTrimChanged,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 140,
    this.showSegmentNumbers = true,
    this.cornerRadius = kWaveCornerRadius,
  });

  /// Peaks of the visible range: [peaks] are laid out exactly over [view].
  final WaveformPeaks peaks;

  /// File range that fits into the window.
  final AudioTrim view;

  /// Segment boundaries in file milliseconds.
  final List<int> boundaries;

  /// Playhead position in file milliseconds.
  final int positionMs;

  final ValueChanged<List<int>> onBoundariesChanged;

  /// Removes an inner marker on a double tap; `null` forbids removal.
  final ValueChanged<int>? onBoundaryRemoved;

  /// Where the playhead moved; `null` keeps it fixed.
  final ValueChanged<int>? onSeek;

  /// Range that survives trimming; `null` when trimming is off.
  final AudioTrim? trim;

  final ValueChanged<AudioTrim>? onTrimChanged;

  final int? activeSegmentIndex;
  final bool showCursor;
  final double height;

  /// Whether to show segment numbers on the waveform.
  final bool showSegmentNumbers;

  /// Card corner radius the painter clips the waveform with.
  final double cornerRadius;

  @override
  State<WaveformEditor> createState() => _WaveformEditorState();
}

/// Height of the time ruler strip on top.
const double _rulerHeight = 14;

/// Boundary handle dot above the top edge of the waveform.
const double _boundaryHandleDrawY = 2;
const double _boundaryHandleRadius = 7;

/// Corner radius of the waveform card.
const double kWaveCornerRadius = 14;

/// Triangular playhead handle at the bottom edge of the waveform.
const double _playheadHandleHeight = 14;

/// Trim handle tab in the middle of the waveform.
const double _trimHandleWidth = 15;
const double _trimHandleHeight = 30;

class _WaveformEditorState extends State<WaveformEditor> {
  /// Radius within which a playhead or trim handle counts as grabbed.
  static const double _handleGrabRadius = 22;

  /// Boundary grab area: a strip along the top of the waveform.
  static const double _boundaryGrabHalfWidth = 22;
  static const double _boundaryGrabBottom = 48;

  /// Waveform zoom limits.
  static const double _minZoom = 1;
  static const double _maxZoom = 200;

  /// Edge strip that makes the waveform auto-scroll.
  static const double _autoScrollZone = 28;
  static const double _autoScrollPixelsPerTick = 6;
  static const Duration _autoScrollTick = Duration(milliseconds: 16);

  late List<int> _boundaries = List<int>.of(widget.boundaries);
  int? _draggedIndex;

  /// Trim while its handle is dragged; it is reported on release.
  late AudioTrim? _trim = widget.trim;
  TrimEdge? _draggedTrimEdge;

  /// Playhead position while dragged; it is reported on release.
  int? _draggedPlayheadMs;

  /// How many times wider than the window the waveform is.
  double _zoom = 1;

  /// Window offset along the zoomed waveform, in pixels from its start.
  double _offset = 0;

  double _viewportWidth = 0;
  double _zoomAtScaleStart = 1;
  double? _dragPointerX;
  Timer? _autoScrollTimer;

  /// Last double-tap point, used to find the marker to remove.
  Offset? _doubleTapPos;

  @override
  void didUpdateWidget(WaveformEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // While a marker is dragged, outer updates do not overwrite local state.
    if (_draggedIndex == null && widget.boundaries != oldWidget.boundaries) {
      _boundaries = List<int>.of(widget.boundaries);
    }
    if (_draggedTrimEdge == null && widget.trim != oldWidget.trim) {
      _trim = widget.trim;
    }
    // The window moved — reset zoom and offset.
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

  /// Screen coordinate of a moment in time.
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

  /// Changes zoom keeping the moment under [focalX] in place.
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

  // --- Input -----------------------------------------------------------------

  /// Handles wheel and pinch: waveform zoom or panning.
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
        // A fully visible waveform is not scrolled: the wheel goes to the form.
        resolver.register(event, (resolved) {
          final scroll = resolved as PointerScrollEvent;
          // A vertical wheel scrolls the waveform too.
          _setOffset(_offset + scroll.scrollDelta.dx + scroll.scrollDelta.dy);
        });
      }
    } else if (event is PointerScaleEvent) {
      // Trackpad pinch.
      resolver.register(event, (resolved) {
        final scale = resolved as PointerScaleEvent;
        _setZoom(_zoom * scale.scale, scale.localPosition.dx);
      });
    }
  }

  /// The playhead is visible only where it can be controlled.
  bool get _hasPlayhead => widget.onSeek != null && widget.showCursor;

  /// Whether trimming is on; boundary markers freeze meanwhile.
  bool get _isTrimming => _trim != null;

  int get _playheadMs => _draggedPlayheadMs ?? widget.positionMs;

  bool get _isDragging =>
      _draggedIndex != null ||
      _draggedPlayheadMs != null ||
      _draggedTrimEdge != null;

  /// Center of the triangular playhead handle.
  Offset get _playheadHandleCenter =>
      Offset(_msToX(_playheadMs), widget.height - _playheadHandleHeight / 2);

  /// Center of the trim tab inside the range that is kept.
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

    // Look for the nearest marker inside the grab strip at the top.
    var nearest = -1;
    var nearestDistance = double.infinity;
    if (!_isTrimming && point.dy <= _boundaryGrabBottom) {
      for (var i = 1; i < _boundaries.length - 1; i++) {
        final dx = (_msToX(_boundaries[i]) - point.dx).abs();
        if (dx < nearestDistance) {
          nearestDistance = dx;
          nearest = i;
        }
      }
    }

    // Of the neighbouring handles the closest one wins.
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
    if (nearest > 0 && nearestDistance <= _boundaryGrabHalfWidth) {
      setState(() => _draggedIndex = nearest);
      _dragPointerX = point.dx;
    }
    // Missing the handles sends the gesture to waveform panning.
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

  /// Moves whatever was grabbed: a trim handle, a boundary or the playhead.
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

  /// Scrolls the waveform while a marker is held at the window edge.
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

  /// A tap on the waveform moves the playhead.
  void _onTapUp(TapUpDetails details) {
    final onSeek = widget.onSeek;
    if (onSeek == null) return;
    onSeek(_view.clampMs(_xToMs(details.localPosition.dx)));
  }

  void _onDoubleTapDown(TapDownDetails details) =>
      _doubleTapPos = details.localPosition;

  /// A double tap on a marker dot removes it.
  void _onDoubleTap() {
    final onRemoved = widget.onBoundaryRemoved;
    final point = _doubleTapPos;
    if (onRemoved == null || point == null || _isTrimming) return;
    if (point.dy > _boundaryGrabBottom) return;
    var nearest = -1;
    var nearestDistance = double.infinity;
    for (var i = 1; i < _boundaries.length - 1; i++) {
      final dx = (_msToX(_boundaries[i]) - point.dx).abs();
      if (dx < nearestDistance) {
        nearestDistance = dx;
        nearest = i;
      }
    }
    if (nearest > 0 && nearestDistance <= _boundaryGrabHalfWidth) {
      onRemoved(nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<WaveformColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The window stays put when the width changes.
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
            // Double tap is caught only where markers can be removed, else
            // the recognizer would delay a plain tap-to-seek.
            onDoubleTapDown:
                widget.onBoundaryRemoved == null ? null : _onDoubleTapDown,
            onDoubleTap:
                widget.onBoundaryRemoved == null ? null : _onDoubleTap,
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
                cornerRadius: widget.cornerRadius,
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
    required this.cornerRadius,
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
  final double cornerRadius;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    // We clip the wave ourselves so handle dots can overflow the card.
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cornerRadius),
      ),
    );
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);
    if (view.isEmpty) {
      canvas.restore();
      return;
    }

    final waveTop = _rulerHeight;
    final waveHeight = size.height - _rulerHeight;
    final centerY = waveTop + waveHeight / 2;
    final halfHeight = waveHeight / 2 - 4;

    _paintActiveSegment(canvas, size);
    _paintWave(canvas, size, centerY, halfHeight);
    _paintRuler(canvas, size);
    _paintBoundaryLines(canvas, size);
    _paintSegmentNumbers(canvas, size);
    _paintTrim(canvas, size, centerY);
    _paintCursor(canvas, size);
    _paintScrollbar(canvas, size);
    _paintZoomLabel(canvas, size);
    canvas.restore();

    // Handle dots are painted outside the clip and overflow the card edge.
    _paintBoundaryHandles(canvas, size);
  }

  /// Full width of the zoomed waveform.
  double _contentWidth(double viewportWidth) => viewportWidth * zoom;

  double _msToX(int ms, double width) =>
      (ms - view.startMs) / view.durationMs * _contentWidth(width) - offset;

  int _xToMs(double x, double width) =>
      view.startMs +
      ((x + offset) / _contentWidth(width) * view.durationMs).round();

  /// Time from the start of the visible range — that is what the user sees.
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
    // Only the visible bars are painted.
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

  /// Paints the time ruler with ticks.
  void _paintRuler(Canvas canvas, Size size) {
    final stepMs = _rulerStepMs(size.width);
    if (stepMs <= 0) return;
    final paint = Paint()
      ..color = colors.wave.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final fromMs = math.max(view.startMs, _xToMs(0, size.width));
    final toMs = math.min(view.endMs, _xToMs(size.width, size.width));
    // The step starts at the window left edge so labels land on round numbers.
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

  /// A round tick step at which labels do not overlap.
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

  /// Vertical boundary lines, painted inside the waveform clip.
  void _paintBoundaryLines(Canvas canvas, Size size) {
    // While trimming, segment markers are drawn dimmer.
    final alpha = trim == null ? 1.0 : 0.35;
    final edgePaint = Paint()
      ..color = colors.boundary.withValues(alpha: 0.4 * alpha)
      ..strokeWidth = 1;
    final linePaint = Paint()
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
      final paint = i == draggedIndex
          ? (Paint()
              ..color = colors.boundary
              ..strokeWidth = 3)
          : linePaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  /// Paints handle dots at the top end of the boundary lines.
  void _paintBoundaryHandles(Canvas canvas, Size size) {
    final alpha = trim == null ? 1.0 : 0.35;
    for (var i = 1; i < boundaries.length - 1; i++) {
      final rawX = _msToX(boundaries[i], size.width);
      if (rawX < -8 || rawX > size.width + 8) continue;
      final x = rawX.clamp(0.5, size.width - 0.5);
      final isDragged = i == draggedIndex;
      canvas.drawCircle(
        Offset(x, _boundaryHandleDrawY),
        isDragged ? _boundaryHandleRadius + 2 : _boundaryHandleRadius,
        Paint()..color = colors.boundary.withValues(alpha: alpha),
      );
      // The marker number inside the dot.
      final number = _layoutLabel(
        '$i',
        colors.background.withValues(alpha: alpha),
        9,
      );
      number.paint(
        canvas,
        Offset(
          x - number.width / 2,
          _boundaryHandleDrawY - number.height / 2,
        ),
      );
      if (isDragged) {
        // While a marker is dragged, show the exact time under the finger.
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
      // The number stays inside the visible part of the segment.
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

  /// Paints the trimmed-away scrim and the trim handles.
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

    // The tab sits on the side that is kept.
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

    // The arrow points into the range that is kept.
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
    final strokeWidth = isPlayheadDragged ? 3.0 : 2.0;
    // A dark backing under the white cursor keeps it visible on a light wave.
    final backing = Paint()
      ..color = const Color(0x59000000)
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), backing);
    final paint = Paint()
      ..color = colors.cursor
      ..strokeWidth = strokeWidth;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    if (!isPlayheadDraggable) return;

    // The playhead handle is a triangle at the bottom.
    final width = isPlayheadDragged ? 13.0 : 10.0;
    final baseY = size.height - _playheadHandleHeight;
    final triangle = Path()
      ..moveTo(x - width / 2, size.height)
      ..lineTo(x + width / 2, size.height)
      ..lineTo(x, baseY)
      ..close();
    canvas.drawPath(
      triangle,
      Paint()
        ..color = const Color(0x59000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawPath(triangle, Paint()..color = colors.cursor);
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

  /// Current zoom label; not painted on an unzoomed waveform.
  void _paintZoomLabel(Canvas canvas, Size size) {
    if (zoom <= 1.05) return;
    final text = '${zoom < 10 ? zoom.toStringAsFixed(1) : zoom.round()}×';
    final painter = _layoutLabel(text, colors.wave, 10);
    painter.paint(
      canvas,
      Offset(size.width - painter.width - 6, size.height - painter.height - 8),
    );
  }

  /// Indicator of the visible window on a zoomed waveform.
  void _paintScrollbar(Canvas canvas, Size size) {
    final contentWidth = _contentWidth(size.width);
    if (zoom <= 1 || contentWidth <= 0) return;
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
        oldDelegate.cornerRadius != cornerRadius ||
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
