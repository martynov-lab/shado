import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../widgets/lessons_error_view.dart';
import '../../widgets/phrase_card.dart';
import '../../widgets/phrase_rating_row.dart';
import '../../widgets/phrase_set_header.dart';
import '../../widgets/phrase_set_toolbar.dart';
import '../../widgets/phrase_set_transport.dart';
import 'phrase_set_wm.dart';
import 'phrase_study_mode.dart';

/// A phrase set studied card by card: listening and repeating, or recalling
/// a phrase from its translation and flipping the card.
class PhraseSetPage extends ElementaryWidget<PhraseSetWidgetModel> {
  const PhraseSetPage({super.key, required this.lessonId})
    : super(phraseSetWidgetModelFactory);

  /// Route template; [routeTo] builds a path to a specific set.
  static const String routePath = '/phrases/:id';

  static String routeTo(String lessonId) => '/phrases/$lessonId';

  static String editRouteTo(String lessonId) => '/phrases/$lessonId/edit';

  final String lessonId;

  @override
  Widget build(PhraseSetWidgetModel wm) {
    return Focus(
      focusNode: wm.pageFocus,
      autofocus: true,
      onKeyEvent: wm.handleKey,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          wm.state,
          wm.stars,
          wm.machineTranslations,
          wm.translationLanguage,
          wm.canEdit,
          wm.download,
          wm.isOnline,
        ]),
        builder: (context, _) => Scaffold(
          backgroundColor: context.colors.bg,
          body: SafeArea(
            child: switch (wm.state.value) {
              AsyncFailed(:final error) => Column(
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
              AsyncReady(value: final state) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  children: [
                    PhraseSetHeader(
                      title: state.lesson.title,
                      counter: wm.counter(state),
                      canEdit: wm.canEdit.value,
                      onBack: wm.back,
                      onEdit: () => unawaited(wm.edit()),
                      download: wm.download.value,
                      onToggleDownload: wm.canToggleDownload
                          ? () => unawaited(wm.toggleDownload())
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    PhraseSetToolbar(
                      mode: state.mode,
                      isShuffled: state.isShuffled,
                      deckLabel: wm.deckLabel(state),
                      onModeChanged: wm.setMode,
                      onToggleShuffle: wm.toggleShuffle,
                      onSelect: () =>
                          unawaited(wm.openPhrases(selecting: true)),
                      onResetDeck: wm.resetDeck,
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppBreakpoints.tablet,
                          ),
                          child: state.isEmpty
                              ? const Text('This set has no phrases yet')
                              : GestureDetector(
                                  onHorizontalDragEnd: (details) => wm.swipe(
                                    details.primaryVelocity ?? 0,
                                  ),
                                  child: PhraseCard(
                                    faceKey:
                                        '${state.current.id}-'
                                        '${wm.needsFlip(state)}',
                                    text: wm.cardFace(state).text,
                                    secondary: wm.cardFace(state).secondary,
                                    hint: wm.cardFace(state).hint,
                                    onTap: wm.needsFlip(state)
                                        ? wm.flip
                                        : () => unawaited(
                                            wm.openPhrases(selecting: false),
                                          ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (!state.isEmpty)
                      wm.needsFlip(state)
                          ? AppButton(
                              label: 'Flip',
                              icon: Icons.flip_rounded,
                              size: AppButtonSize.lg,
                              onPressed: wm.flip,
                            )
                          : PhraseRatingRow(
                              stars: wm.currentStars(state),
                              onChanged: (stars) => unawaited(wm.rate(stars)),
                            ),
                    const SizedBox(height: AppSpacing.s4),
                    PhraseSetTransport(
                      isPlaying: state.isPlaying,
                      isRepeating: state.isRepeating,
                      isLooping: state.isLooping,
                      canLoop: state.mode == PhraseStudyMode.listen,
                      speedLabel: '${state.speed}×',
                      onToggleRepeat: wm.toggleRepeat,
                      onPrevious: wm.previous,
                      onTogglePlay: wm.togglePlay,
                      onNext: wm.next,
                      onToggleLoop: wm.toggleLoop,
                      onPickSpeed: () => unawaited(wm.pickSpeed()),
                    ),
                  ],
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }
}
