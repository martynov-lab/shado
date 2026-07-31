import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/edit_lesson_controller.dart';
import 'edit_lesson_waveform.dart';
import 'segment_text_field.dart';

/// Тело экрана правки: название, разбивка текста и волна с границами.
class EditLessonForm extends ConsumerStatefulWidget {
  const EditLessonForm({
    super.key,
    required this.lessonId,
    required this.state,
  });

  final String lessonId;
  final EditLessonState state;

  @override
  ConsumerState<EditLessonForm> createState() => _EditLessonFormState();
}

class _EditLessonFormState extends ConsumerState<EditLessonForm> {
  late final _titleController = TextEditingController(text: widget.state.title);
  late final _textController = TextEditingController(text: widget.state.text);

  /// Фокус самого экрана: пока он здесь, пробел работает как play/pause.
  final _pageFocus = FocusNode(debugLabel: 'edit-lesson-page');

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  EditLessonController get _controller =>
      ref.read(editLessonControllerProvider(widget.lessonId).notifier);

  /// Пробел как play/pause — привычка из любого редактора аудио.
  ///
  /// Срабатывает только когда фокус на самом экране: в текстовом поле пробел
  /// остаётся пробелом, а на кнопке ▶ его обрабатывает сама кнопка.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.space ||
        !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    _controller.togglePlay();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final controller = _controller;

    return Focus(
      focusNode: _pageFocus,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
              textInputAction: TextInputAction.next,
              onChanged: controller.setTitle,
            ),
            const SizedBox(height: 16),
            SegmentTextField(
              controller: _textController,
              onChanged: controller.setText,
              segmentCount: state.segmentCount,
            ),
            const SizedBox(height: 16),
            // Тронули волну — забираем фокус из текстового поля, иначе пробел
            // так и останется пробелом.
            Listener(
              onPointerDown: (_) => _pageFocus.requestFocus(),
              child: EditLessonWaveform(
                lessonId: widget.lessonId,
                state: state,
                onPlayPressed: controller.togglePlay,
                onSeek: controller.seek,
                onBoundariesChanged: controller.setBoundaries,
                onTrimChanged: controller.updateTrim,
                onTrimStart: controller.startTrim,
                onTrimApply: controller.applyTrim,
                onTrimCancel: controller.cancelTrim,
              ),
            ),
            const SizedBox(height: 8),
            Text(_hint(state), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Подсказка под волной: что сейчас можно сделать жестами и клавишами.
String _hint(EditLessonState state) {
  if (state.isTrimming) {
    return 'Тяните метки со стрелочками: затемнённые края отрежутся. '
        '«Применить» оставит только середину, «Отменить» вернёт как было. '
        'Пробел — послушать';
  }
  return 'Метки берутся за кружок сверху, ползунок — за треугольник снизу; '
      'перетаскивание в стороне от них двигает волну. Растянуть волну: щипок '
      'двумя пальцами или Ctrl + колесо мыши. Пробел — играть или пауза';
}
