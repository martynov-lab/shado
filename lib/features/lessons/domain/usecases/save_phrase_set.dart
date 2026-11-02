import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../entities/lesson_category.dart';
import '../entities/phrase_draft.dart';
import '../repositories/lesson_repository.dart';

/// Server limit of phrases in one set.
const int kMaxPhrasesInSet = 200;

/// What the phrase set editor saves.
class PhraseSetForm {
  const PhraseSetForm({
    required this.title,
    required this.phrases,
    required this.level,
    this.accent,
    this.topicId,
    this.isPublic,
  });

  final String title;
  final List<PhraseDraft> phrases;
  final LessonLevel? level;
  final String? accent;
  final String? topicId;

  /// `null` lets the server pick the default, a private set.
  final bool? isPublic;
}

/// Creates or updates a phrase set; phrases without text are dropped.
class SavePhraseSet {
  const SavePhraseSet(this._repository);

  final LessonRepository _repository;

  /// Creates the set when [existing] is `null`, otherwise replaces it.
  Future<Lesson> call(PhraseSetForm form, {Lesson? existing}) {
    final title = form.title.trim();
    if (title.isEmpty) {
      throw const ValidationFailure('Enter a title');
    }
    final level = form.level;
    if (level == null) {
      throw const ValidationFailure('Choose a level');
    }
    final drafts = [
      for (final draft in form.phrases)
        if (draft.hasText) draft,
    ];
    if (drafts.isEmpty) {
      throw const ValidationFailure('Add at least one phrase');
    }
    if (drafts.length > kMaxPhrasesInSet) {
      throw const ValidationFailure(
        'A set holds at most $kMaxPhrasesInSet phrases',
      );
    }
    if (drafts.any((draft) => draft.needsVoice)) {
      throw const ValidationFailure('Voice every phrase before saving');
    }
    final phrases = [for (final draft in drafts) draft.toPhrase()];
    if (existing == null) {
      return _repository.createPhraseSet(
        title: title,
        phrases: phrases,
        level: level,
        accent: form.accent,
        topicId: form.topicId,
        isPublic: form.isPublic,
      );
    }
    return _repository.updatePhraseSet(
      existing.copyWith(
        title: title,
        phrases: phrases,
        level: level,
        accent: form.accent,
        topic: form.topicId == null
            ? null
            : Topic(id: form.topicId!, name: existing.topic?.name ?? ''),
      ),
      isPublic: form.isPublic,
    );
  }
}
