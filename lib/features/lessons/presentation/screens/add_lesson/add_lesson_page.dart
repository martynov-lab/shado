import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/utils/duration_format.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../domain/usecases/synthesize_tts.dart';
import '../../widgets/add_lesson_waveform.dart';
import '../../widgets/lesson_category_fields.dart';
import '../../widgets/lesson_editor_header.dart';
import '../../widgets/lesson_file_chip.dart';
import '../../widgets/lesson_privacy_field.dart';
import '../../widgets/lesson_section_card.dart';
import '../../widgets/segment_splitter/segment_splitter_field.dart';
import '../../widgets/tts_quota_hint.dart';
import 'add_lesson_wm.dart';

/// New lesson: audio (a file or an AI voice-over), title, category and the
/// text split into segments on the waveform.
class AddLessonPage extends ElementaryWidget<AddLessonWidgetModel> {
  const AddLessonPage({super.key}) : super(addLessonWidgetModelFactory);

  static const String routePath = '/add';

  @override
  Widget build(AddLessonWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.form,
        wm.topics,
        wm.accents,
        wm.session,
        wm.quotaLeft,
        wm.canSubmit,
      ]),
      builder: (context, _) {
        final state = wm.form.value;
        final isBusy = state.isSubmitting || state.isUploading;
        // The privacy switch and the AI voice-over are owner-only.
        final isOwner = wm.session.value.isOwner;

        return Scaffold(
          backgroundColor: context.colors.bg,
          body: SafeArea(
            child: Column(
              children: [
                LessonEditorHeader(
                  title: 'New lesson',
                  onBack: wm.back,
                  primaryLabel: 'Create lesson',
                  onPrimary: wm.canSubmit.value ? wm.submit : null,
                  primaryLoading: state.isSubmitting,
                ),
                Expanded(
                  child: Focus(
                    focusNode: wm.pageFocus,
                    autofocus: true,
                    onKeyEvent: wm.handleKey,
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
                          onPick: isBusy ? null : wm.pickAudio,
                          onCancelUpload: wm.cancelUpload,
                          canSynthesize: isOwner,
                          // There is nothing to voice over for empty text.
                          onSynthesize:
                              isBusy ||
                                  SynthesizeTts.prepareText(state.text).isEmpty
                              ? null
                              : wm.synthesize,
                          helper:
                              'Supported: ${allowedAudioExtensions.join(', ')}, '
                              'up to ${AppConfig.maxUploadBytes ~/ (1024 * 1024)} MB',
                        ),
                        if (isOwner) TtsQuotaHint(remaining: wm.quotaLeft.value),
                        const SizedBox(height: AppSpacing.s5),
                        AppTextField(
                          controller: wm.titleController,
                          label: 'Title',
                          hint: 'For example, TED: How language shapes thought',
                          onChanged: wm.setTitle,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        LessonCategoryFields(
                          accent: state.accent,
                          level: state.level,
                          topicId: state.topicId,
                          topics: wm.topics.value,
                          accents: wm.accents.value,
                          isBusy: isBusy,
                          onAccentChanged: wm.setAccent,
                          onLevelChanged: wm.setLevel,
                          onTopicChanged: wm.setTopic,
                        ),
                        if (isOwner) ...[
                          const SizedBox(height: AppSpacing.s4),
                          LessonPrivacyField(
                            isPrivate: !state.isPublic,
                            onChanged: wm.setPrivate,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s5),
                        LessonSectionCard(
                          label: 'Audio',
                          note: '— set the segment boundaries',
                          child: Listener(
                            onPointerDown: (_) => wm.focusPage(),
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                wm.isPlaying,
                                wm.playheadMs,
                              ]),
                              builder: (_, _) => AddLessonWaveform(
                                state: state,
                                isPlaying: wm.isPlaying.value,
                                playheadMs: wm.playheadMs.value,
                                onSeek: wm.seekPreview,
                                onTogglePlay: wm.togglePreview,
                                onBoundariesChanged: wm.setBoundaries,
                                onBoundaryRemoved: wm.removeMarker,
                                onMarkerAtPlayheadChanged:
                                    wm.setMarkerAtPlayhead,
                                onTrimChanged: wm.updateTrim,
                                onTrimStart: wm.startTrim,
                                onTrimApply: wm.applyTrim,
                                onTrimCancel: wm.cancelTrim,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        LessonSectionCard(
                          label: 'Text',
                          note: '— split into segments',
                          hint:
                              'Press "Marker" and click in the text where the '
                              'delimiter goes (or drag the chip) — the waveform boundary '
                              'lands right of the rightmost one. With "Marker at '
                              'playhead" on, it lands at the playhead. A needle can be '
                              'dragged or removed with a tap. The server receives text '
                              'with "$kSegmentDelimiter".',
                          child: SegmentSplitterField(
                            controller: wm.textController,
                            onChanged: wm.setText,
                            onMarkerInserted: wm.insertMarker,
                            onMarkerRemoved: wm.removeMarker,
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
      },
    );
  }
}
