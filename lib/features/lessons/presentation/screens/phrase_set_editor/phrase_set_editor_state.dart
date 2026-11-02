import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/phrase_draft.dart';

/// What the phrase set editor shows: the set fields, the phrase rows and
/// which long action is running.
class PhraseSetEditorState {
  const PhraseSetEditorState({
    this.title = '',
    this.accent,
    this.level,
    this.topicId,
    this.isPublic = false,
    this.phrases = const [],
    this.isVoicing = false,
    this.isTranslating = false,
    this.isSaving = false,
  });

  final String title;
  final String? accent;
  final LessonLevel? level;
  final String? topicId;
  final bool isPublic;
  final List<PhraseDraft> phrases;

  final bool isVoicing;
  final bool isTranslating;
  final bool isSaving;

  bool get isBusy => isVoicing || isTranslating || isSaving;

  /// Phrases with text but without up-to-date audio.
  List<PhraseDraft> get toVoice => [
    for (final phrase in phrases)
      if (phrase.needsVoice) phrase,
  ];

  /// Phrases with text but without a translation into [language].
  List<PhraseDraft> missingTranslations(String language) => [
    for (final phrase in phrases)
      if (phrase.hasText && phrase.translationFor(language).trim().isEmpty)
        phrase,
  ];

  /// Whether the set can be saved; [needsAccent] for languages with accents.
  bool canSave({required bool needsAccent}) =>
      !isBusy &&
      title.trim().isNotEmpty &&
      level != null &&
      (!needsAccent || accent != null) &&
      phrases.any((phrase) => phrase.hasText) &&
      toVoice.isEmpty;

  PhraseSetEditorState copyWith({
    String? title,
    String? accent,
    LessonLevel? level,
    String? topicId,
    bool? isPublic,
    List<PhraseDraft>? phrases,
    bool? isVoicing,
    bool? isTranslating,
    bool? isSaving,
  }) => PhraseSetEditorState(
    title: title ?? this.title,
    accent: accent ?? this.accent,
    level: level ?? this.level,
    topicId: topicId ?? this.topicId,
    isPublic: isPublic ?? this.isPublic,
    phrases: phrases ?? this.phrases,
    isVoicing: isVoicing ?? this.isVoicing,
    isTranslating: isTranslating ?? this.isTranslating,
    isSaving: isSaving ?? this.isSaving,
  );

  /// Replaces the phrase with [id] by [update] of it.
  PhraseSetEditorState updatePhrase(
    String id,
    PhraseDraft Function(PhraseDraft phrase) update,
  ) => copyWith(
    phrases: [
      for (final phrase in phrases)
        if (phrase.id == id) update(phrase) else phrase,
    ],
  );
}
