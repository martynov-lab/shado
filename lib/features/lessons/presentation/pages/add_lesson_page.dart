import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/utils/duration_format.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/usecases/synthesize_tts.dart';
import '../controllers/add_lesson_controller.dart';
import '../controllers/add_lesson_playback_controller.dart';
import '../controllers/lesson_providers.dart';
import '../widgets/add_lesson_waveform.dart';
import '../widgets/lesson_category_fields.dart';
import '../widgets/lesson_editor_header.dart';
import '../widgets/lesson_file_chip.dart';
import '../widgets/lesson_privacy_field.dart';
import '../widgets/lesson_section_card.dart';
import '../widgets/synthesize_tts_dialog.dart';
import '../widgets/segment_splitter/marked_text_controller.dart';
import '../widgets/segment_splitter/segment_splitter_field.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'lesson_page.dart';

class AddLessonPage extends ConsumerStatefulWidget {
  const AddLessonPage({super.key});

  static const String routePath = '/add';

  @override
  ConsumerState<AddLessonPage> createState() => _AddLessonPageState();
}

class _AddLessonPageState extends ConsumerState<AddLessonPage> {
  final _titleController = TextEditingController();
  final _textController = MarkedTextController();

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

  /// Озвучивает текст через ИИ. Если аудио уже выбрано, синтез заменит его —
  /// сначала спрашиваем подтверждение.
  Future<void> _synthesize() async {
    if (ref.read(addLessonControllerProvider).audioId != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const SynthesizeTtsDialog(),
      );
      if (confirmed != true) return;
    }
    try {
      await ref.read(addLessonControllerProvider.notifier).synthesizeTts();
    } on ApiException catch (error) {
      _showTtsError(error);
    } catch (error) {
      _showMessage('Не удалось озвучить: $error');
    }
  }

  /// Показывает ошибку озвучки по TTS_CLIENT_SPEC §4. Сервис временно недоступен
  /// (503) — зовём попробовать позже и даём «Повторить». Исчерпан лимит (429) —
  /// авто-ретраем не долбим, а предлагаем запасной путь: загрузить свой файл.
  void _showTtsError(ApiException error) {
    if (!mounted) return;
    switch (error.code) {
      case ApiErrorCode.ttsUnavailable:
        showAppSnackbar(
          context,
          message: 'Озвучка временно недоступна. Попробуйте позже.',
          variant: AppSnackbarVariant.warning,
          actionLabel: 'Повторить',
          onAction: _synthesize,
        );
      case ApiErrorCode.ttsQuotaExceeded:
        showAppSnackbar(
          context,
          message: error.message,
          variant: AppSnackbarVariant.warning,
          actionLabel: 'Загрузить файл',
          onAction: _pickAudio,
        );
      case _:
        _showMessage('Не удалось озвучить: ${error.message}');
    }
  }

  /// Метку поставили в тексте — сажаем парную границу под ползунок. Позицию
  /// берём ту же, что показывает волна: пока играет — живую, на паузе — где
  /// оставили.
  void _insertMarker(String text, int ordinal) {
    final controller = ref.read(addLessonControllerProvider.notifier);
    // Без волны разметки ещё нет — позиция плеера не нужна, и поднимать его ради
    // неё незачем.
    if (!ref.read(addLessonControllerProvider).hasWaveform) {
      controller.insertMarker(text, ordinal, 0);
      return;
    }
    final playback = ref.read(addLessonPlaybackProvider);
    final position = ref.read(addPlaybackPositionProvider).value;
    final playheadMs = playback.isPlaying
        ? (position?.inMilliseconds ?? playback.playheadMs)
        : playback.playheadMs;
    controller.insertMarker(text, ordinal, playheadMs);
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
    final isBusy = state.isSubmitting || state.isUploading;
    // Тумблер приватности показываем только владельцу: остальным авторам
    // публичность задаёт роль.
    final isOwner = ref.watch(authControllerProvider).isOwner;

    // Пока форму заполняли, выбранную тему могли удалить на другом устройстве.
    // Убираем её из состояния, чтобы на сервер не уехал мёртвый id.
    ref.listen(topicsProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        controller.dropTopicUnless([for (final topic in list) topic.id]);
      }
    });

    // Метку могли удалить с волны — тогда текст правит контроллер, и его нужно
    // вернуть в поле. При обычном вводе текст уже совпадает, синк — no-op.
    ref.listen(addLessonControllerProvider.select((s) => s.text), (_, next) {
      if (next != _textController.text) _textController.text = next;
    });

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            LessonEditorHeader(
              title: 'Новый урок',
              onBack: () => context.go(HomePage.routePath),
              primaryLabel: 'Создать урок',
              onPrimary: state.canSubmit ? _submit : null,
              primaryLoading: state.isSubmitting,
            ),
            Expanded(
              child: Focus(
                focusNode: _pageFocus,
                autofocus: true,
                onKeyEvent: _onKeyEvent,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.s5),
                  children: [
                    LessonFileChip(
                      fileName: state.audioFileName,
                      detail: state.durationMs > 0
                          ? formatPosition(state.durationMs)
                          : null,
                      isUploading: state.isUploading,
                      uploadProgress: state.uploadProgress,
                      isSynthesizing: state.isSynthesizing,
                      onPick: isBusy ? null : _pickAudio,
                      onCancelUpload: controller.cancelUpload,
                      // Озвучивать нечего, пока в тексте нет ни одной фразы.
                      onSynthesize:
                          isBusy ||
                              SynthesizeTts.prepareText(state.text).isEmpty
                          ? null
                          : _synthesize,
                      helper:
                          'Поддерживаются ${allowedAudioExtensions.join(', ')}, '
                          'до ${AppConfig.maxUploadBytes ~/ (1024 * 1024)} МБ',
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    AppTextField(
                      controller: _titleController,
                      label: 'Название',
                      hint: 'Например, TED: How language shapes thought',
                      onChanged: controller.setTitle,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    LessonCategoryFields(
                      accent: state.accent,
                      level: state.level,
                      topicId: state.topicId,
                      topics: topics,
                      isBusy: isBusy,
                      onAccentChanged: controller.setAccent,
                      onLevelChanged: controller.setLevel,
                      onTopicChanged: controller.setTopic,
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: AppSpacing.s4),
                      LessonPrivacyField(
                        isPrivate: !state.isPublic,
                        onChanged: controller.setPrivate,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s5),
                    LessonSectionCard(
                      label: 'Аудио',
                      note: '— расставь границы сегментов',
                      // Тронули волну — забираем фокус из текстового поля, иначе
                      // пробел так и останется пробелом.
                      child: Listener(
                        onPointerDown: (_) => _pageFocus.requestFocus(),
                        child: AddLessonWaveform(
                          state: state,
                          onBoundariesChanged: controller.setBoundaries,
                          onBoundaryRemoved: controller.removeMarker,
                          onTrimChanged: controller.updateTrim,
                          onTrimStart: controller.startTrim,
                          onTrimApply: controller.applyTrim,
                          onTrimCancel: controller.cancelTrim,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    LessonSectionCard(
                      label: 'Текст',
                      note: '— разбей на сегменты',
                      hint:
                          'Доведите плеер до паузы между фразами, затем нажмите '
                          '«Метка» и кликните в тексте, куда поставить '
                          'разделитель (или перетащите чип) — граница на волне '
                          'встанет в позицию ползунка. Иглу можно перетащить или '
                          'убрать тапом. На сервер уходит текст '
                          'с «$kSegmentDelimiter».',
                      child: SegmentSplitterField(
                        controller: _textController,
                        onChanged: controller.setText,
                        onMarkerInserted: _insertMarker,
                        onMarkerRemoved: controller.removeMarker,
                        segmentCount: state.segmentCount,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
