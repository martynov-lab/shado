import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final controller = ref.read(
      editLessonControllerProvider(widget.lessonId).notifier,
    );

    return SafeArea(
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
          WaveformCard(
            audioPath: state.lesson.audioPath,
            durationMs: state.lesson.durationMs,
            boundaries: state.boundaries,
            onBoundariesChanged: controller.setBoundaries,
            margin: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Text(
            'Перетащите метки, чтобы совместить куски с речью. '
            'Растянуть волну: «+/−», щипок или Ctrl + колесо мыши',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
