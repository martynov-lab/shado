import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../controllers/add_lesson_controller.dart';
import '../widgets/segment_text_field.dart';
import '../widgets/waveform_card.dart';

class AddLessonPage extends ConsumerStatefulWidget {
  const AddLessonPage({super.key});

  @override
  ConsumerState<AddLessonPage> createState() => _AddLessonPageState();
}

class _AddLessonPageState extends ConsumerState<AddLessonPage> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      await ref.read(addLessonControllerProvider.notifier).pickAudio();
    } catch (error) {
      _showMessage('Не удалось выбрать файл: $error');
    }
  }

  Future<void> _submit() async {
    final controller = ref.read(addLessonControllerProvider.notifier);
    try {
      final lesson = await controller.submit();
      if (!mounted) return;
      _titleController.clear();
      _textController.clear();
      context.push('/lesson/${lesson.id}');
    } catch (error) {
      _showMessage('Не удалось создать урок: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addLessonControllerProvider);
    final controller = ref.read(addLessonControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить урок')),
      body: SafeArea(
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
            OutlinedButton.icon(
              onPressed: state.isSubmitting ? null : _pickAudio,
              icon: const Icon(Icons.audiotrack),
              label: Text(state.audioFileName ?? 'Выбрать аудио'),
            ),
            const SizedBox(height: 8),
            Text(
              'Поддерживаются ${allowedAudioExtensions.join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _WaveformPreview(state: state, controller: controller),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.canSubmit ? _submit : null,
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать урок'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Волна выбранного файла с метками границ — разметка и обрезка идут ещё до
/// создания урока, чтобы куски сразу попали на свои места.
class _WaveformPreview extends StatelessWidget {
  const _WaveformPreview({required this.state, required this.controller});

  final AddLessonFormState state;
  final AddLessonController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.isProbingAudio) {
      return const Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 168,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (!state.hasWaveform) {
      return Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 96,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Выберите аудио — здесь появится волна с метками границ',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WaveformCard(
          audioPath: state.audioPath!,
          durationMs: state.durationMs,
          view: state.view,
          boundaries: state.boundaries,
          onBoundariesChanged: controller.setBoundaries,
          // Файл ещё чужой: кеш пиков рядом с ним не создаём.
          cachePeaks: false,
          margin: EdgeInsets.zero,
          trim: state.pendingTrim,
          onTrimChanged: controller.updateTrim,
          onTrimStart: controller.startTrim,
          onTrimApply: controller.applyTrim,
          onTrimCancel: controller.cancelTrim,
        ),
        const SizedBox(height: 8),
        Text(_hint(state), style: theme.textTheme.bodySmall),
      ],
    );
  }

  String _hint(AddLessonFormState state) {
    if (state.isTrimming) {
      return 'Тяните метки со стрелочками: затемнённые края отрежутся. '
          '«Применить» оставит только середину, «Отменить» вернёт как было';
    }
    if (state.segmentCount == 0) {
      return 'Введите текст — метки границ появятся на волне';
    }
    return 'Метки берутся за кружок сверху, перетаскивание в стороне от них '
        'двигает волну. Растянуть волну: щипок двумя пальцами или Ctrl + '
        'колесо мыши';
  }
}
