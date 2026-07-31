import 'package:flutter/material.dart';

import 'package:shado/core/constants/app_constants.dart';

import '../controllers/lesson_controller.dart';
import 'segment_tile.dart';

/// Тело экрана урока: переключатель скорости и список кусков.
///
/// Состояние приходит готовым, действия уходят колбэками — виджет ничего не
/// знает ни о контроллере, ни о том, какой урок открыт.
class LessonView extends StatefulWidget {
  const LessonView({
    super.key,
    required this.state,
    required this.onSpeedChanged,
    required this.onPlayPressed,
    required this.onLoopPressed,
    required this.onSelectPressed,
    required this.onSegmentPressed,
  });

  final LessonState state;

  final ValueChanged<double> onSpeedChanged;

  /// Индекс куска: играть, зациклить, выбрать, сделать текущим для клавиатуры.
  final ValueChanged<int> onPlayPressed;
  final ValueChanged<int> onLoopPressed;
  final ValueChanged<int> onSelectPressed;
  final ValueChanged<int> onSegmentPressed;

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> {
  /// Ключи плиток: по ним прокручиваем список к куску, на который перешли
  /// стрелкой.
  final _itemKeys = <int, GlobalKey>{};

  @override
  void didUpdateWidget(LessonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.state.focusedIndex;
    if (index != null && index != oldWidget.state.focusedIndex) {
      _ensureVisible(index);
    }
  }

  void _ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _itemKeys[index]?.currentContext;
      // Плитки далеко за окном ещё не построены — там и прокручивать нечего:
      // стрелки ходят по одному куску, следующий всегда рядом.
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final segments = state.lesson.segments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: kSlowSpeed, label: Text('Медленно')),
              ButtonSegment(value: kNormalSpeed, label: Text('Нормально')),
            ],
            selected: {state.speed},
            onSelectionChanged: (selection) =>
                widget.onSpeedChanged(selection.first),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: segments.length,
            itemBuilder: (context, index) => SegmentTile(
              key: _itemKeys[index] ??= GlobalKey(),
              segment: segments[index],
              isActive: state.isSegmentActive(index),
              isPlaying: state.isSegmentPlaying(index),
              isLooped: state.isSegmentLooped(index),
              isSelecting: state.isSelecting,
              isSelected: state.isSegmentSelected(index),
              isFocused: state.focusedIndex == index,
              onPlayPressed: () => widget.onPlayPressed(index),
              onLoopPressed: () => widget.onLoopPressed(index),
              onSelectPressed: () => widget.onSelectPressed(index),
              onPressed: () => widget.onSegmentPressed(index),
            ),
          ),
        ),
      ],
    );
  }
}
