import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../entities/lesson_category.dart';
import '../entities/phrase.dart';
import '../entities/segment_range.dart';
import '../repositories/lesson_repository.dart';
import 'save_phrase_set.dart';

/// How many neighbouring segments make one phrase at most: a sentence is
/// often cut in two.
const int kMaxSegmentsPerPhrase = 2;

/// Turns 1–2 story segments into a phrase of a set. The phrase plays the
/// story audio range, so nothing is cut or voiced.
class AddPhraseFromStory {
  const AddPhraseFromStory(this._repository, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final LessonRepository _repository;
  final Uuid _uuid;

  /// Adds the phrase to [target], or to a new private set when it is `null`.
  Future<Lesson> call({
    required Lesson story,
    required SegmentRange range,
    Lesson? target,
    Map<String, String> translations = const {},
  }) {
    if (story.isExpressions || story.audioId.isEmpty) {
      throw const ValidationFailure('A phrase is taken from a story only');
    }
    if (range.length > kMaxSegmentsPerPhrase ||
        range.start < 0 ||
        range.end >= story.segmentCount) {
      throw const ValidationFailure(
        'Pick one or two neighbouring segments for a phrase',
      );
    }
    if (target != null && story.isPrivate && target.isPublic) {
      throw const ValidationFailure(
        'A phrase from a private story goes to a private set only',
      );
    }
    if (target != null && target.phrases.length >= kMaxPhrasesInSet) {
      throw const ValidationFailure(
        'The set already holds $kMaxPhrasesInSet phrases',
      );
    }
    final first = story.segments[range.start];
    final last = story.segments[range.end];
    final phrase = Phrase(
      id: _uuid.v4(),
      text: [
        for (var i = range.start; i <= range.end; i++)
          story.segments[i].text.trim(),
      ].join(' '),
      translations: translations,
      audioId: story.audioId,
      audioPath: story.audioPath,
      durationMs: last.endMs - first.startMs,
      startMs: first.startMs,
      endMs: last.endMs,
      sourceLessonId: story.id,
    );
    if (target == null) {
      return _repository.createPhraseSet(
        title: 'Phrases: ${story.title}',
        phrases: [phrase],
        level: story.level ?? LessonLevel.b1,
        accent: story.accent,
        topicId: story.topic?.id,
        isPublic: false,
      );
    }
    return _repository.updatePhraseSet(
      target.copyWith(phrases: [...target.phrases, phrase]),
    );
  }
}
