import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../../core/constants/app_constants.dart';
import 'marked_text_controller.dart';
import 'segment_boundary_math.dart';
import 'segment_marker.dart';

/// Данные перетаскивания метки. [fromMarkerIndex] — индекс символа метки,
/// которую взяли; `null` — тащат новую из чипа-источника.
class _MarkerDrag {
  const _MarkerDrag(this.fromMarkerIndex);

  final int? fromMarkerIndex;
}

/// Метка в тексте и её точное место в поле.
typedef _MarkerHit = ({int index, Rect rect});

/// Ширина области, которой ловится тап/перетаскивание иглы поверх текста.
const double _pinHitWidth = 24;

/// Высота иглы-курсора в режиме постановки — примерно строка текста.
const double _cursorNeedleHeight = 30;

/// Текст урока с разбивкой на сегменты иглами-метками вместо ручного «|».
///
/// Слова печатаются как в обычном поле. Разделитель ставится двумя способами:
/// на десктопе — кнопкой «Метка» (курсор в поле становится иглой, клик ставит
/// метку ровно в позицию каретки и режим выключается); на любой платформе —
/// перетаскиванием чипа «Метка» в нужное место. Уже поставленную иглу можно
/// перетащить в другое место, убрать тапом или вытащив за пределы поля.
///
/// Место каждой метки берётся из самого поля ([RenderEditable]), поэтому игла
/// стоит ровно там, где символ «|» — который невидим и уходит на сервер как
/// есть.
class SegmentSplitterField extends StatefulWidget {
  const SegmentSplitterField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onMarkerInserted,
    required this.onMarkerRemoved,
    required this.segmentCount,
    this.focusNode,
    this.enabled = true,
  });

  final MarkedTextController controller;
  final ValueChanged<String> onChanged;

  /// Постановка новой метки №[ordinal] (1-based) с уже готовым текстом. В отличие
  /// от [onChanged] контроллер не раскладывает границы заново, а ставит парную
  /// границу в текущую позицию плеера.
  final void Function(String text, int ordinal) onMarkerInserted;

  /// Удаление метки №[ordinal] (1-based). Текст правит не поле, а контроллер:
  /// парная граница на аудио убирается там же, а новый текст возвращается в
  /// поле извне.
  final ValueChanged<int> onMarkerRemoved;

  final int segmentCount;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  State<SegmentSplitterField> createState() => _SegmentSplitterFieldState();
}

class _SegmentSplitterFieldState extends State<SegmentSplitterField> {
  /// Контейнер текста: и точка отсчёта координат, и корень поиска [RenderEditable].
  final _fieldKey = GlobalKey();

  /// Иглы с их местами, пересчитанные после раскладки поля.
  List<_MarkerHit> _markers = const [];

  /// Идёт режим постановки метки кликом (десктоп).
  bool _placing = false;

  /// Позиция мыши в поле, пока держим режим постановки; `null` — курсора нет.
  Offset? _cursorPos;

  /// Куда встанет метка при отпускании перетаскивания; `null` — не тащим.
  Rect? _indicatorRect;

  static const double _padH = AppSpacing.s4;
  static const double _padV = AppSpacing.s4;

  MarkedTextController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = AppText.body.copyWith(
      color: colors.text,
      fontSize: 16,
      height: 1.9,
    );
    final strutStyle = StrutStyle.fromTextStyle(baseStyle, forceStrutHeight: true);
    final hasMarkers = _controller.text.contains(kSegmentDelimiter);

    // Места игл берём из поля уже после его раскладки — иначе координаты
    // относятся к прошлому тексту.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMarkers());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildSource(),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                'Сегментов: ${widget.segmentCount}',
                style: AppText.monoTime.copyWith(color: colors.text2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            AppButton(
              label: 'Сбросить',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: widget.enabled && hasMarkers ? _clearAll : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        MouseRegion(
          cursor: _placing ? SystemMouseCursors.none : MouseCursor.defer,
          onHover: _placing ? _onHover : null,
          onExit: _placing ? (_) => _setCursor(null) : null,
          child: DragTarget<_MarkerDrag>(
            onMove: (details) => _updateIndicator(details.offset),
            onLeave: (_) => _setIndicator(null),
            onAcceptWithDetails: (details) =>
                _onAccept(details.data, details.offset),
            builder: (context, candidate, rejected) {
              final active = _placing || candidate.isNotEmpty;
              return Stack(
                children: [
                  Container(
                    key: _fieldKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _padH,
                      vertical: _padV,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(
                        color: active ? colors.primary : colors.border,
                        width: active
                            ? AppSizes.borderThick
                            : AppSizes.borderThin,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: widget.focusNode,
                      enabled: widget.enabled,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: baseStyle,
                      strutStyle: strutStyle,
                      cursorColor: colors.primary,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: 'Вставьте текст урока…',
                        hintStyle: baseStyle.copyWith(color: colors.text3),
                      ),
                    ),
                  ),
                  // Вне режима метки — интерактивные иглы; в режиме постановки
                  // те же метки видны, но приглушены, чтобы не спорить с яркой
                  // иглой-курсором новой метки.
                  if (widget.enabled && !_placing) ..._buildPins(colors),
                  if (widget.enabled && _placing)
                    for (final marker in _markers)
                      _needleAt(marker.rect, colors.primary, opacity: 0.4),
                  if (_indicatorRect case final rect?)
                    _needleAt(rect, colors.primary, opacity: 0.5),
                  if (_placing && _cursorPos != null)
                    Positioned(
                      left: _cursorPos!.dx - kNeedleCircle / 2,
                      top: _cursorPos!.dy - _cursorNeedleHeight / 2,
                      width: kNeedleCircle,
                      height: _cursorNeedleHeight,
                      child: IgnorePointer(
                        child: SegmentMarkerNeedle(
                          height: _cursorNeedleHeight,
                          color: colors.primary,
                          ringColor: colors.surface2,
                        ),
                      ),
                    ),
                  // В режиме постановки клик по тексту ловим сами — им ставим
                  // метку, а не двигаем каретку.
                  if (_placing)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: _placeAtTap,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Чип-источник: тап включает режим постановки, перетаскивание переносит метку
  /// в текст на любой платформе.
  Widget _buildSource() {
    if (!widget.enabled) return const SegmentMarkerChip(enabled: false);
    return GestureDetector(
      onTap: _startPlacing,
      child: Draggable<_MarkerDrag>(
        data: const _MarkerDrag(null),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: const SegmentMarkerGhost(),
        childWhenDragging: const SegmentMarkerChip(enabled: false),
        child: const SegmentMarkerChip(),
      ),
    );
  }

  List<Widget> _buildPins(AppColors colors) {
    return [
      // Метки идут по порядку (_markers отсортирован по позиции), поэтому номер
      // метки — её место в списке.
      for (final (position, marker) in _markers.indexed)
        _needleAt(
          marker.rect,
          colors.primary,
          hitWidth: _pinHitWidth,
          pin: _MarkerPin(
            markerIndex: marker.index,
            number: position + 1,
            height: marker.rect.height,
            color: colors.primary,
            ringColor: colors.surface2,
            onDelete: () => widget.onMarkerRemoved(position + 1),
          ),
        ),
    ];
  }

  /// Позиционирует иглу (или её ручку) по прямоугольнику каретки метки.
  Widget _needleAt(
    Rect rect,
    Color color, {
    double opacity = 1,
    double hitWidth = kNeedleCircle,
    Widget? pin,
  }) {
    return Positioned(
      left: rect.left - hitWidth / 2,
      top: rect.top,
      width: hitWidth,
      height: rect.height,
      child:
          pin ??
          IgnorePointer(
            child: SegmentMarkerNeedle(
              height: rect.height,
              color: color,
              opacity: opacity,
            ),
          ),
    );
  }

  // --- Геометрия из самого поля ---------------------------------------------

  RenderEditable? _renderEditable() {
    final object = _fieldKey.currentContext?.findRenderObject();
    return _searchEditable(object);
  }

  RenderEditable? _searchEditable(RenderObject? node) {
    if (node is RenderEditable) return node;
    RenderEditable? found;
    node?.visitChildren((child) => found ??= _searchEditable(child));
    return found;
  }

  /// Прямоугольник каретки для позиции [offset] в координатах поля.
  Rect? _caretRect(int offset) {
    final editable = _renderEditable();
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (editable == null || box == null) return null;
    final local = editable.getLocalRectForCaret(TextPosition(offset: offset));
    final global = editable.localToGlobal(local.topLeft);
    return box.globalToLocal(global) & Size(local.width, local.height);
  }

  /// Позиция каретки под точкой [globalPosition].
  int? _offsetForPoint(Offset globalPosition) =>
      _renderEditable()?.getPositionForPoint(globalPosition).offset;

  void _syncMarkers() {
    if (!mounted) return;
    final indices = markerIndices(_controller.text);
    final next = <_MarkerHit>[];
    for (final index in indices) {
      final rect = _caretRect(index);
      if (rect != null) next.add((index: index, rect: rect));
    }
    if (listEquals(next, _markers)) return;
    setState(() => _markers = next);
  }

  // --- Постановка, перенос, удаление ----------------------------------------

  void _startPlacing() {
    if (!widget.enabled) return;
    setState(() => _placing = true);
  }

  void _placeAtTap(TapUpDetails details) {
    final offset = _offsetForPoint(details.globalPosition);
    setState(() => _placing = false);
    if (offset == null) return;
    _insertAt(offset);
  }

  /// Ставит метку в позицию каретки [offset] и, если она добавилась, отдаёт её
  /// порядковый номер контроллеру — тот посадит парную границу под ползунок.
  void _insertAt(int offset) {
    final text = _controller.text;
    final next = insertMarkerAt(text, offset);
    if (next == text) return;
    final at = offset.clamp(0, text.length);
    final ordinal = markerIndices(next).indexOf(at) + 1;
    _apply(next, caretAfterInsert(offset), insertedOrdinal: ordinal);
  }

  void _onHover(PointerHoverEvent event) => _setCursor(event.localPosition);

  void _setCursor(Offset? position) {
    if (_cursorPos == position) return;
    setState(() => _cursorPos = position);
  }

  void _setIndicator(Rect? rect) {
    if (_indicatorRect == rect) return;
    setState(() => _indicatorRect = rect);
  }

  void _updateIndicator(Offset globalPosition) {
    final offset = _offsetForPoint(globalPosition);
    _setIndicator(offset == null ? null : _caretRect(offset));
  }

  void _onAccept(_MarkerDrag drag, Offset globalPosition) {
    final offset = _offsetForPoint(globalPosition);
    _setIndicator(null);
    if (offset == null) return;
    final text = _controller.text;
    final from = drag.fromMarkerIndex;
    if (from == null) {
      _insertAt(offset);
      return;
    }
    final next = moveMarker(text, from, offset);
    if (next != text) _apply(next, offset.clamp(0, next.length));
  }

  void _clearAll() {
    final next = clearMarkers(_controller.text);
    if (next == _controller.text) return;
    _apply(next, next.length);
  }

  /// Программная правка текста: обновляет поле и, поскольку `TextField.onChanged`
  /// на такие правки не срабатывает, сам зовёт колбэк. При вставке метки
  /// ([insertedOrdinal] задан) зовёт [onMarkerInserted] — граница ляжет под
  /// ползунок, а не разложится заново.
  void _apply(String text, int caret, {int? insertedOrdinal}) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret.clamp(0, text.length)),
    );
    if (insertedOrdinal != null) {
      widget.onMarkerInserted(text, insertedOrdinal);
    } else {
      widget.onChanged(text);
    }
  }
}

/// Игла-ручка поверх текста: тащат — переносят метку, тап или перенос за
/// пределы поля — убирают.
class _MarkerPin extends StatelessWidget {
  const _MarkerPin({
    required this.markerIndex,
    required this.number,
    required this.height,
    required this.color,
    required this.ringColor,
    required this.onDelete,
  });

  /// Индекс символа метки в тексте — по нему её переносят при перетаскивании.
  final int markerIndex;

  /// Порядковый номер метки — его показывают в кружке и им же метку удаляют.
  final int number;
  final double height;
  final Color color;
  final Color ringColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Draggable<_MarkerDrag>(
      data: _MarkerDrag(markerIndex),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: SegmentMarkerNeedle(height: height, color: color),
      childWhenDragging: const SizedBox.shrink(),
      onDraggableCanceled: (_, _) => onDelete(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDelete,
        child: Center(
          child: SegmentMarkerNeedle(
            height: height,
            color: color,
            ringColor: ringColor,
            number: number,
          ),
        ),
      ),
    );
  }
}
