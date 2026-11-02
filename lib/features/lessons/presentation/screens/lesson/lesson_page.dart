import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../widgets/lesson_countdown_overlay.dart';
import '../../widgets/lesson_gradients.dart';
import '../../widgets/lesson_header.dart';
import '../../widgets/lesson_mobile_layout.dart';
import '../../widgets/lesson_player_panel.dart';
import '../../widgets/lesson_player_waveform.dart';
import '../../widgets/lesson_segments_button.dart';
import '../../widgets/lesson_segments_panel.dart';
import '../../widgets/lesson_transcript_panel.dart';
import '../../widgets/lesson_wide_layout.dart';
import '../../widgets/lessons_error_view.dart';
import 'lesson_wm.dart';

/// The lesson: segment text, the player and the segment list.
class LessonPage extends ElementaryWidget<LessonWidgetModel> {
  const LessonPage({super.key, required this.lessonId})
    : super(lessonWidgetModelFactory);

  /// Route template; [routeTo] builds a path to a specific lesson.
  static const String routePath = '/lesson/:id';

  static String routeTo(String lessonId) => '/lesson/$lessonId';

  final String lessonId;

  @override
  Widget build(LessonWidgetModel wm) {
    return Focus(
      focusNode: wm.pageFocus,
      autofocus: true,
      onKeyEvent: wm.handleKey,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          wm.state,
          wm.canEdit,
          wm.download,
          wm.isOnline,
          wm.stars,
        ]),
        builder: (context, _) => Scaffold(
          backgroundColor: context.colors.bg,
          body: switch (wm.state.value) {
            AsyncFailed(:final error) => SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.s2),
                    child: AppIconButton(
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: 'Back',
                      onPressed: wm.back,
                    ),
                  ),
                  Expanded(
                    child: LessonsErrorView(
                      message: wm.errorText(error),
                      onRetryPressed: () => unawaited(wm.retry()),
                    ),
                  ),
                ],
              ),
            ),
            AsyncReady(value: final state) => Stack(
              children: [
                AppAdaptiveLayout(
                  mobile: (_) => LessonMobileLayout(
                    header: LessonHeader(
                      state: state,
                      canEdit: wm.canEdit.value,
                      onBack: wm.back,
                      onEdit: () => unawaited(wm.edit()),
                      download: wm.download.value,
                      onToggleDownload: wm.canToggleDownload
                          ? () => unawaited(wm.toggleDownload())
                          : null,
                    ),
                    transcript: ValueListenableBuilder(
                      valueListenable: wm.translation,
                      builder: (_, translation, _) => LessonTranscriptPanel(
                        text: state.playerText,
                        translation: translation,
                        onToggleTranslation: wm.toggleTranslation,
                        stars: wm.playerStars(state),
                        onRate: (stars) => unawaited(wm.rate(stars)),
                      ),
                    ),
                    segmentsButton: LessonSegmentsButton(
                      currentIndex: state.currentIndex,
                      count: state.lesson.segmentCount,
                      onTap: () => unawaited(wm.openSegments()),
                    ),
                    player: LessonPlayerPanel(
                      state: state,
                      waveform: ValueListenableBuilder(
                        valueListenable: wm.playedFraction,
                        builder: (_, fraction, _) => LessonPlayerWaveform(
                          color: lessonPlayerForeground,
                          playedFraction: fraction,
                        ),
                      ),
                      onPrevious: wm.previous,
                      onTogglePlay: wm.togglePlayCurrent,
                      onNext: wm.next,
                      onPickSpeed: () => unawaited(wm.pickSpeed()),
                      onToggleLoop: wm.toggleLoop,
                    ),
                  ),
                  tablet: (_) => LessonWideLayout(
                    header: LessonHeader(
                      state: state,
                      canEdit: wm.canEdit.value,
                      onBack: wm.back,
                      onEdit: () => unawaited(wm.edit()),
                      download: wm.download.value,
                      onToggleDownload: wm.canToggleDownload
                          ? () => unawaited(wm.toggleDownload())
                          : null,
                    ),
                    transcript: ValueListenableBuilder(
                      valueListenable: wm.translation,
                      builder: (_, translation, _) => LessonTranscriptPanel(
                        text: state.playerText,
                        translation: translation,
                        onToggleTranslation: wm.toggleTranslation,
                        stars: wm.playerStars(state),
                        onRate: (stars) => unawaited(wm.rate(stars)),
                      ),
                    ),
                    player: LessonPlayerPanel(
                      state: state,
                      waveform: ValueListenableBuilder(
                        valueListenable: wm.playedFraction,
                        builder: (_, fraction, _) => LessonPlayerWaveform(
                          color: lessonPlayerForeground,
                          playedFraction: fraction,
                        ),
                      ),
                      onPrevious: wm.previous,
                      onTogglePlay: wm.togglePlayCurrent,
                      onNext: wm.next,
                      onPickSpeed: () => unawaited(wm.pickSpeed()),
                      onToggleLoop: wm.toggleLoop,
                    ),
                    segments: LessonSegmentsPanel(
                      state: state,
                      segmentStars: wm.segmentStars(state),
                      onSegmentPressed: wm.goToSegment,
                      onSelectPressed: wm.toggleSelection,
                      onStartSelecting: wm.startSelecting,
                      onSelectAll: wm.selectAll,
                      onClearSelection: wm.clearSelection,
                      onDone: wm.finishSelecting,
                      onToggleLoop: wm.toggleLoop,
                      onAddToPhrases: wm.canAddToPhrases(state)
                          ? () => unawaited(wm.addSelectionToPhraseSet())
                          : null,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: LessonCountdownOverlay(countdown: state.countdown),
                ),
              ],
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}
