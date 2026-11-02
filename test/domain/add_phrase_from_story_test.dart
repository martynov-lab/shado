import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_kind.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/domain/entities/segment_range.dart';
import 'package:shado/features/lessons/domain/usecases/add_phrase_from_story.dart';

import '../presentation/fake_lesson_repository.dart';

Lesson _story({bool isPublic = true}) => Lesson(
  id: 'story-1',
  title: 'TED talk',
  audioId: 'story-audio',
  audioPath: '/cache/story-audio.mp3',
  durationMs: 9000,
  createdAt: DateTime.utc(2026, 11, 2),
  isPublic: isPublic,
  segments: const [
    Segment(index: 0, text: 'I would like', startMs: 0, endMs: 1200),
    Segment(index: 1, text: 'a window seat.', startMs: 1200, endMs: 2500),
    Segment(index: 2, text: 'Thank you.', startMs: 2500, endMs: 3000),
  ],
);

Lesson _set({bool isPublic = false}) => Lesson(
  id: 'set-1',
  title: 'Travel',
  audioPath: '',
  durationMs: 0,
  createdAt: DateTime.utc(2026, 11, 2),
  segments: const [],
  kind: LessonKind.expressions,
  isPublic: isPublic,
);

void main() {
  late FakeLessonRepository repository;
  late AddPhraseFromStory add;

  setUp(() {
    repository = FakeLessonRepository();
    add = AddPhraseFromStory(repository);
  });

  test('two segments become one phrase over the story range', () async {
    await add(
      story: _story(),
      range: const SegmentRange(0, 1),
      target: _set(),
      translations: const {'ru': 'Я бы хотел место у окна.'},
    );

    final phrase = repository.savedSets.single.phrases.single;
    expect(phrase.text, 'I would like a window seat.');
    expect(phrase.audioId, 'story-audio');
    expect(phrase.startMs, 0);
    expect(phrase.endMs, 2500);
    expect(phrase.durationMs, 2500);
    expect(phrase.sourceLessonId, 'story-1');
    expect(phrase.translationFor('ru'), 'Я бы хотел место у окна.');
  });

  test('without a target a new private set is created', () async {
    final created = await add(story: _story(), range: const SegmentRange(2, 2));

    expect(created.isPrivate, isTrue);
    expect(created.title, 'Phrases: TED talk');
    expect(created.phrases.single.text, 'Thank you.');
  });

  test('more than two segments are refused', () {
    expect(
      () => add(story: _story(), range: const SegmentRange(0, 2)),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('a phrase from a private story never goes to a public set', () {
    expect(
      () => add(
        story: _story(isPublic: false),
        range: const SegmentRange(0, 0),
        target: _set(isPublic: true),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
