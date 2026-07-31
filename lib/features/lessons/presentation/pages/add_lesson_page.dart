import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/add_lesson_controller.dart';
import '../controllers/add_lesson_playback_controller.dart';
import '../controllers/lesson_providers.dart';
import '../widgets/add_lesson_waveform.dart';
import '../widgets/lesson_category_fields.dart';
import '../widgets/segment_text_field.dart';
import '../widgets/upload_progress.dart';
import 'lesson_page.dart';

class AddLessonPage extends ConsumerStatefulWidget {
  const AddLessonPage({super.key});

  static const String routePath = '/add';

  @override
  ConsumerState<AddLessonPage> createState() => _AddLessonPageState();
}

class _AddLessonPageState extends ConsumerState<AddLessonPage> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  /// Фокус самого экрана: пока он здесь, пробел работает как play/pause.
  final _pageFocus = FocusNode(debugLabel: 'add-lesson-page');

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
    // Файла ещё нет — не поднимаем плеер вхолостую: под `autoDispose` он тут же
    // и закрылся бы.
    if (ref.read(addLessonControllerProvider).audioPath == null) {
      return KeyEventResult.ignored;
    }
    ref.read(addLessonPlaybackProvider.notifier).togglePlay();
    return KeyEventResult.handled;
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
      context.push(LessonPage.routeTo(lesson.id));
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
    final topics = ref.watch(topicsProvider);
    final theme = Theme.of(context);

    // Пока форму заполняли, выбранную тему могли удалить на другом устройстве.
    // Убираем её из состояния, чтобы на сервер не уехал мёртвый id.
    ref.listen(topicsProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        controller.dropTopicUnless([for (final topic in list) topic.id]);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить урок')),
      body: Focus(
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
              LessonCategoryFields(
                accent: state.accent,
                level: state.level,
                topicId: state.topicId,
                topics: topics,
                isBusy: state.isSubmitting || state.isUploading,
                onAccentChanged: controller.setAccent,
                onLevelChanged: controller.setLevel,
                onTopicChanged: controller.setTopic,
              ),
              const SizedBox(height: 16),
              SegmentTextField(
                controller: _textController,
                onChanged: controller.setText,
                segmentCount: state.segmentCount,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: state.isSubmitting || state.isUploading
                    ? null
                    : _pickAudio,
                icon: const Icon(Icons.audiotrack),
                label: Text(state.audioFileName ?? 'Выбрать аудио'),
              ),
              const SizedBox(height: 8),
              if (state.isUploading)
                UploadProgress(
                  progress: state.uploadProgress,
                  onCancelPressed: controller.cancelUpload,
                )
              else
                Text(
                  'Поддерживаются ${allowedAudioExtensions.join(', ')}, '
                  'до ${AppConfig.maxUploadBytes ~/ (1024 * 1024)} МБ',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              // Тронули волну — забираем фокус из текстового поля, иначе пробел
              // так и останется пробелом.
              Listener(
                onPointerDown: (_) => _pageFocus.requestFocus(),
                child: AddLessonWaveform(
                  state: state,
                  onBoundariesChanged: controller.setBoundaries,
                  onTrimChanged: controller.updateTrim,
                  onTrimStart: controller.startTrim,
                  onTrimApply: controller.applyTrim,
                  onTrimCancel: controller.cancelTrim,
                ),
              ),
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
      ),
    );
  }
}
