import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/phrase_model.dart';
import 'package:shado/features/lessons/domain/entities/lesson_kind.dart';
import 'package:shado/features/lessons/domain/entities/phrase.dart';

void main() {
  const storyPhraseJson = {
    'id': 'c03d',
    'text': "I'd like a window seat.",
    'translations': {'ru': 'Место у окна.', 'de': ''},
    'audio': {
      'id': 'story-audio',
      'url': 'https://x/v1/audio/story-audio/file',
      'content_type': 'audio/mpeg',
      'size_bytes': 90000,
      'sha256': 'abc',
      'duration_ms': 60000,
    },
    'duration_ms': 2750,
    'start_ms': 41200,
    'end_ms': 43950,
    'source_lesson_id': 'f9e2',
  };

  test('a phrase from a story keeps its range and source', () {
    final phrase = PhraseModel.fromJson(storyPhraseJson).toEntity();

    expect(phrase.audioId, 'story-audio');
    expect(phrase.playStartMs, 41200);
    expect(phrase.playEndMs, 43950);
    expect(phrase.sourceLessonId, 'f9e2');
    expect(phrase.translationFor('ru'), 'Место у окна.');
    // An empty translation counts as missing.
    expect(phrase.translationFor('de'), isNull);
  });

  test('a phrase with its own file plays the whole file', () {
    const phrase = Phrase(id: 'p', text: 'Hi', audioId: 'a', durationMs: 1830);

    expect(phrase.playStartMs, 0);
    expect(phrase.playEndMs, 1830);
  });

  test('the cache shape reads back to the same phrase', () {
    final model = PhraseModel.fromJson(
      storyPhraseJson,
    ).withAudioPath('/cache/story-audio.mp3');

    final restored = PhraseModel.fromCacheJson(model.toCacheJson());

    expect(restored.toEntity(), model.toEntity());
    expect(restored.audio.sha256, 'abc');
    expect(restored.audio.fileExtension, 'mp3');
  });

  test('the request carries the audio id and drops empty translations', () {
    final json = PhraseModel.requestJson(
      PhraseModel.fromJson(storyPhraseJson).toEntity(),
    );

    expect(json, {
      'id': 'c03d',
      'text': "I'd like a window seat.",
      'translations': {'ru': 'Место у окна.'},
      'audio_id': 'story-audio',
      'start_ms': 41200,
      'end_ms': 43950,
      'source_lesson_id': 'f9e2',
    });
  });

  test('a lesson without a kind is a story, item keys follow the kind', () {
    final story = LessonDto.fromJson({
      'id': 'l1',
      'audio': {'id': 'a1'},
      'segments': [
        {'index': 0, 'text': 'Hello there.', 'start_ms': 0, 'end_ms': 10},
      ],
    }).toEntity(audioPath: '');
    final set = LessonDto.fromJson({
      'id': 's1',
      'kind': 'expressions',
      'phrases': [storyPhraseJson],
    }).toEntity(audioPath: '');

    expect(story.kind, LessonKind.story);
    expect(story.itemKeys, ['s:92ea4f7debacecc2']);
    expect(set.isExpressions, isTrue);
    expect(set.itemKeys, ['p:c03d']);
  });
}
