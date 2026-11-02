import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../widgets/lesson_category_fields.dart';
import '../../widgets/lesson_editor_header.dart';
import '../../widgets/lesson_privacy_field.dart';
import '../../widgets/lessons_error_view.dart';
import '../../widgets/phrase_draft_row.dart';
import '../../widgets/phrase_set_editor_actions.dart';
import 'phrase_set_editor_wm.dart';

/// Phrase set editor: the set fields, phrases with translations, the batch
/// translation and voice-over. Without [lessonId] it creates a new set.
class PhraseSetEditorPage extends ElementaryWidget<PhraseSetEditorWidgetModel> {
  const PhraseSetEditorPage({super.key, this.lessonId})
    : super(phraseSetEditorWidgetModelFactory);

  /// Creation inside the add section.
  static const String createPath = '/add/phrases';

  /// Editing, nested under the phrase set route.
  static const String routeSegment = 'edit';

  final String? lessonId;

  @override
  Widget build(PhraseSetEditorWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.loading,
        wm.state,
        wm.topics,
        wm.accents,
        wm.role,
        wm.translationLanguage,
        wm.quotaLeft,
        wm.playingId,
      ]),
      builder: (context, _) {
        final state = wm.state.value;
        final language = wm.translationLanguage.value;
        final translationHint =
            'Translation (${wm.translationLanguageLabel(language)})';

        return Scaffold(
          backgroundColor: context.colors.bg,
          body: SafeArea(
            child: Column(
              children: [
                LessonEditorHeader(
                  title: wm.isEditing ? 'Edit phrases' : 'New phrase set',
                  onBack: wm.back,
                  primaryLabel: 'Save',
                  onPrimary: wm.canSave ? () => unawaited(wm.save()) : null,
                  primaryLoading: state.isSaving,
                ),
                Expanded(
                  child: switch (wm.loading.value) {
                    AsyncFailed() => LessonsErrorView(
                      message: 'The phrase set failed to load',
                      onRetryPressed: () => unawaited(wm.retry()),
                    ),
                    AsyncPending() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    AsyncReady() => ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.all(AppSpacing.s5),
                      onReorderItem: wm.movePhrase,
                      header: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: wm.titleController,
                            label: 'Title',
                            hint: 'For example, At the airport',
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
                            isBusy: state.isBusy,
                            onAccentChanged: wm.setAccent,
                            onLevelChanged: wm.setLevel,
                            onTopicChanged: wm.setTopic,
                          ),
                          if (wm.canPublish) ...[
                            const SizedBox(height: AppSpacing.s4),
                            LessonPrivacyField(
                              isPrivate: !state.isPublic,
                              onChanged: wm.setPrivate,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.s5),
                          Text(
                            'PHRASES',
                            style: AppText.caption.copyWith(
                              color: context.colors.text3,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      footer: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.s3,
                            runSpacing: AppSpacing.s2,
                            children: [
                              AppButton(
                                label: 'Add phrase',
                                icon: Icons.add_rounded,
                                variant: AppButtonVariant.ghost,
                                onPressed: state.isBusy ? null : wm.addPhrase,
                              ),
                              AppButton(
                                label: 'Paste text',
                                icon: Icons.content_paste_rounded,
                                variant: AppButtonVariant.ghost,
                                onPressed: state.isBusy
                                    ? null
                                    : () => unawaited(wm.importText()),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          PhraseSetEditorActions(
                            toTranslate: state
                                .missingTranslations(language)
                                .length,
                            toVoice: state.toVoice.length,
                            isTranslating: state.isTranslating,
                            isVoicing: state.isVoicing,
                            isBusy: state.isBusy,
                            quotaLeft: wm.quotaLeft.value,
                            onTranslateAll: () => unawaited(wm.translateAll()),
                            onVoiceAll: () => unawaited(wm.voiceAll()),
                          ),
                        ],
                      ),
                      itemCount: state.phrases.length,
                      itemBuilder: (_, index) {
                        final phrase = state.phrases[index];
                        return PhraseDraftRow(
                          key: ValueKey(phrase.id),
                          index: index,
                          text: phrase.text,
                          translation: phrase.translationFor(language),
                          translationHint: translationHint,
                          hasAudio: phrase.audioPath.isNotEmpty,
                          needsVoice: phrase.needsVoice,
                          isPlaying: wm.playingId.value == phrase.id,
                          isBusy: state.isBusy,
                          onTextChanged: (text) =>
                              wm.setPhraseText(phrase.id, text),
                          onTranslationChanged: (text) =>
                              wm.setPhraseTranslation(phrase.id, text),
                          onTogglePlay: () =>
                              unawaited(wm.togglePhrasePlay(phrase.id)),
                          onVoice: () => unawaited(wm.voicePhrase(phrase.id)),
                          onRemove: () => wm.removePhrase(phrase.id),
                        );
                      },
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
