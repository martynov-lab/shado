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
import '../widgets/tts_quota_hint.dart';
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

  /// Focus of the screen itself; while it is here space acts as play/pause.
  final _pageFocus = FocusNode(debugLabel: 'add-lesson-page');

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  /// Space acts as play/pause while the screen itself holds focus.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.space ||
        !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    // There is no file yet — do not spin up the player for nothing.
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

  /// Runs an AI voice-over, confirming a replacement of the chosen audio.
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
      // The voice-over spent daily quota — re-read what is left.
      ref.invalidate(ttsQuotaProvider);
    } on ApiException catch (error) {
      // The quota is spent — refresh the counter too.
      if (error.code == ApiErrorCode.ttsQuotaExceeded) {
        ref.invalidate(ttsQuotaProvider);
      }
      _showTtsError(error);
    } catch (error) {
      _showMessage('Не удалось озвучить: $error');
    }
  }

  /// Shows a voice-over error with a matching action — retry or upload a
  /// file.
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

  /// Places the paired boundary of a new marker under the playhead.
  void _insertMarker(String text, int ordinal) {
    final controller = ref.read(addLessonControllerProvider.notifier);
    // Without a waveform there is no layout yet, so no playhead is needed.
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
    // The privacy switch and AI voice-over are owner-only.
    final isOwner = ref.watch(authControllerProvider).isOwner;

    // The topic could be deleted elsewhere — drop the dead id.
    ref.listen(topicsProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        controller.dropTopicUnless([for (final topic in list) topic.id]);
      }
    });

    // Text edited by the controller is pushed back into the field.
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
                      canSynthesize: isOwner,
                      // There is nothing to voice over for empty text.
                      onSynthesize:
                          isBusy ||
                              SynthesizeTts.prepareText(state.text).isEmpty
                          ? null
                          : _synthesize,
                      helper:
                          'Поддерживаются ${allowedAudioExtensions.join(', ')}, '
                          'до ${AppConfig.maxUploadBytes ~/ (1024 * 1024)} МБ',
                    ),
                    // The voice-over quota is requested for the owner only.
                    if (isOwner) const TtsQuotaHint(),
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
                      // Touching the waveform takes focus off the text field.
                      child: Listener(
                        onPointerDown: (_) => _pageFocus.requestFocus(),
                        child: AddLessonWaveform(
                          state: state,
                          onBoundariesChanged: controller.setBoundaries,
                          onBoundaryRemoved: controller.removeMarker,
                          onMarkerAtPlayheadChanged:
                              controller.setMarkerAtPlayhead,
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
                          'Нажмите «Метка» и кликните в тексте, куда поставить '
                          'разделитель (или перетащите чип) — граница на волне '
                          'встанет правее самой правой. Включённая «Метка по '
                          'ползунку» сажает её в позицию ползунка. Иглу можно '
                          'перетащить или убрать тапом. На сервер уходит текст '
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
