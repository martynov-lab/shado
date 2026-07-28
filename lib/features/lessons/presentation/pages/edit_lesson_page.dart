import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/duration_format.dart';
import '../controllers/edit_lesson_controller.dart';
import '../widgets/segment_text_field.dart';
import '../widgets/waveform_card.dart';

/// Правка урока: разбивка текста на куски и границы этих кусков на волне.
///
/// Экран возвращает `true`, если правки сохранены — экрану урока по этому
/// признаку надо перечитать себя.
class EditLessonPage extends ConsumerWidget {
  const EditLessonPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(editLessonControllerProvider(lessonId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Правка урока'),
        actions: [
          if (stateAsync.value case final state?)
            TextButton(
              onPressed: state.canSave ? () => _save(context, ref) : null,
              child: state.isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (state) => _EditForm(lessonId: lessonId, state: state),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(editLessonControllerProvider(lessonId).notifier).save();
      navigator.pop(true);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $error')),
      );
    }
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.lessonId, required this.state});

  final String lessonId;
  final EditLessonState state;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
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
    ref
        .read(editLessonControllerProvider(widget.lessonId).notifier)
        .togglePlay();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final controller = ref.read(
      editLessonControllerProvider(widget.lessonId).notifier,
    );

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
              child: _WaveformWithPlayback(
                lessonId: widget.lessonId,
                state: state,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Метки берутся за кружок сверху, ползунок — за треугольник '
              'снизу; перетаскивание в стороне от них двигает волну. Растянуть '
              'волну: щипок двумя пальцами или Ctrl + колесо мыши. Пробел — '
              'играть или пауза',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Волна с ползунком и кнопкой воспроизведения: аудио играет с того места,
/// куда поставили ползунок, повторное нажатие ставит на паузу.
class _WaveformWithPlayback extends ConsumerWidget {
  const _WaveformWithPlayback({required this.lessonId, required this.state});

  final String lessonId;
  final EditLessonState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      editLessonControllerProvider(lessonId).notifier,
    );
    // Пока играет, ползунок ведёт сам плеер; на паузе он стоит там, где его
    // оставили.
    final position = ref.watch(editPlaybackPositionProvider(lessonId)).value;
    final playheadMs = state.isPlaying
        ? (position?.inMilliseconds ?? state.playheadMs)
        : state.playheadMs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WaveformCard(
          audioPath: state.lesson.audioPath,
          durationMs: state.lesson.durationMs,
          boundaries: state.boundaries,
          onBoundariesChanged: controller.setBoundaries,
          onSeek: controller.seek,
          positionMs: playheadMs,
          showCursor: true,
          margin: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              tooltip: state.isPlaying ? 'Пауза' : 'Играть с ползунка',
              onPressed: controller.togglePlay,
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Text(
              '${formatPosition(playheadMs)} / '
              '${formatPosition(state.lesson.durationMs)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
