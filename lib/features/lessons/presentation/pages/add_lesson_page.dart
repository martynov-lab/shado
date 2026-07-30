import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/lesson_category.dart';
import '../controllers/add_lesson_controller.dart';
import '../controllers/add_lesson_playback_controller.dart';
import '../controllers/lesson_providers.dart';
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
              _CategoryFields(state: state, controller: controller),
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
                _UploadProgress(
                  progress: state.uploadProgress,
                  onCancel: controller.cancelUpload,
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
                child: _WaveformPreview(state: state, controller: controller),
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

/// Акцент, уровень и тема — по ним потом фильтруется каталог.
///
/// Акцент и уровень зашиты в клиенте: это закрытые списки, сервер меняет их
/// только релизом. Темы, наоборот, справочник — их правит владелец, поэтому
/// список приходит с сервера при каждом входе на экран.
class _CategoryFields extends ConsumerWidget {
  const _CategoryFields({required this.state, required this.controller});

  final AddLessonFormState state;
  final AddLessonController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final busy = state.isSubmitting || state.isUploading;
    final topics = ref.watch(topicsProvider);
    final available = topics.value ?? const <Topic>[];

    // Пока форму заполняли, выбранную тему могли удалить на другом устройстве.
    // Убираем её из состояния, чтобы на сервер не уехал мёртвый id.
    ref.listen(topicsProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        controller.dropTopicUnless([for (final topic in list) topic.id]);
      }
    });
    // На отрисовку страховка нужна отдельно: список падает, если выбранного
    // значения нет среди пунктов, а слушатель сработает только после кадра.
    final selectedTopic = available.any((topic) => topic.id == state.topicId)
        ? state.topicId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<LessonAccent>(
                key: const ValueKey('dropdown-accent'),
                initialValue: state.accent,
                decoration: const InputDecoration(labelText: 'Акцент'),
                items: [
                  for (final accent in LessonAccent.values)
                    DropdownMenuItem(
                      value: accent,
                      child: Text(
                        accent.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: busy ? null : controller.setAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<LessonLevel>(
                key: const ValueKey('dropdown-level'),
                initialValue: state.level,
                decoration: const InputDecoration(labelText: 'Уровень'),
                // Подписи вида «B1 — средний» в половину строки не влезают,
                // поэтому в закрытом поле остаётся только код уровня.
                selectedItemBuilder: (_) => [
                  for (final level in LessonLevel.values)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(level.wire.toUpperCase()),
                    ),
                ],
                items: [
                  for (final level in LessonLevel.values)
                    DropdownMenuItem(value: level, child: Text(level.label)),
                ],
                onChanged: busy ? null : controller.setLevel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          key: const ValueKey('dropdown-topic'),
          initialValue: selectedTopic,
          decoration: InputDecoration(
            labelText: 'Тема',
            helperText: switch (topics) {
              AsyncError() =>
                'Справочник тем не загрузился — урок создастся '
                    'с темой по умолчанию',
              AsyncLoading() => 'Загружаем справочник тем…',
              _ =>
                'Необязательно: без выбора сервер поставит тему по умолчанию',
            },
            helperMaxLines: 2,
            helperStyle: topics is AsyncError
                ? theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<String?>(child: Text('Без темы')),
            for (final topic in available)
              DropdownMenuItem<String?>(
                value: topic.id,
                child: Text(topic.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          // Пока справочник не пришёл, выбирать нечего.
          onChanged: busy || available.isEmpty ? null : controller.setTopic,
        ),
      ],
    );
  }
}

/// Ход отправки файла на сервер. Полсотни мегабайт летят не мгновенно, поэтому
/// показываем прогресс и даём прервать загрузку.
class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.progress, required this.onCancel});

  final double progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress == 0 ? null : progress),
              const SizedBox(height: 6),
              Text(
                'Загрузка на сервер — ${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(onPressed: onCancel, child: const Text('Отменить')),
      ],
    );
  }
}

/// Волна выбранного файла с метками границ и ползунком воспроизведения —
/// разметка, обрезка и прослушивание идут ещё до создания урока, чтобы куски
/// сразу попали на свои места.
class _WaveformPreview extends ConsumerWidget {
  const _WaveformPreview({required this.state, required this.controller});

  final AddLessonFormState state;
  final AddLessonController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (state.isUploading) {
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
    final playback = ref.watch(addLessonPlaybackProvider);
    final player = ref.read(addLessonPlaybackProvider.notifier);
    // Пока играет, ползунок ведёт сам плеер; на паузе он стоит там, где его
    // оставили.
    final position = ref.watch(addPlaybackPositionProvider).value;
    final playheadMs = playback.isPlaying
        ? (position?.inMilliseconds ?? playback.playheadMs)
        : playback.playheadMs;

    // Время показываем от левого края того, что сейчас в окне: после обрезки
    // урок начинается с нуля, а во время обрезки — начало файла.
    final view = state.view;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WaveformCard(
          audioId: state.audioId!,
          // Файл уже лежит в кеше приложения — запасной локальный построитель
          // волны дотянется до него, если сервер вдруг не ответит.
          audioPath: state.audioPath,
          durationMs: state.durationMs,
          view: view,
          boundaries: state.boundaries,
          onBoundariesChanged: controller.setBoundaries,
          onSeek: player.seek,
          positionMs: playheadMs,
          showCursor: true,
          // Пики считает сервер, а кеш рядом с файлом заведёт уже сам урок:
          // здесь разметку ещё могут бросить, не сохранив.
          cachePeaks: false,
          margin: EdgeInsets.zero,
          trim: state.pendingTrim,
          onTrimChanged: controller.updateTrim,
          onTrimStart: controller.startTrim,
          onTrimApply: controller.applyTrim,
          onTrimCancel: controller.cancelTrim,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              tooltip: playback.isPlaying ? 'Пауза' : 'Играть с ползунка',
              // Файла на диске нет — играть нечего, хотя волна уже пришла.
              onPressed: state.audioPath == null ? null : player.togglePlay,
              icon: Icon(playback.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Text(
              '${formatPosition(playheadMs - view.startMs)} / '
              '${formatPosition(view.durationMs)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_hint(state), style: theme.textTheme.bodySmall),
      ],
    );
  }

  String _hint(AddLessonFormState state) {
    if (state.isTrimming) {
      return 'Тяните метки со стрелочками: затемнённые края отрежутся. '
          '«Применить» оставит только середину, «Отменить» вернёт как было. '
          'Обрезка помогает разметить середину файла, но в сохранённый урок '
          'аудио уходит целиком: края достанутся крайним кускам. '
          'Пробел — послушать';
    }
    if (state.segmentCount == 0) {
      return 'Введите текст — метки границ появятся на волне';
    }
    return 'Метки берутся за кружок сверху, ползунок — за треугольник снизу; '
        'перетаскивание в стороне от них двигает волну. Растянуть волну: щипок '
        'двумя пальцами или Ctrl + колесо мыши. Пробел — играть или пауза';
  }
}
