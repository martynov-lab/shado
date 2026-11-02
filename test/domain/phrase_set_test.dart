import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/phrase.dart';
import 'package:shado/features/lessons/domain/entities/phrase_draft.dart';
import 'package:shado/features/lessons/domain/usecases/save_phrase_set.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_phrases.dart';

import '../presentation/fake_lesson_repository.dart';

const _audio = AudioUpload(
  audioId: 'a1',
  durationMs: 1200,
  sizeBytes: 1,
  localPath: '/cache/a1.wav',
);

void main() {
  group('PhraseDraft', () {
    test('a new phrase with text needs a voice-over', () {
      const draft = PhraseDraft(id: 'p', text: 'Hello');

      expect(draft.needsVoice, isTrue);
      expect(draft.isReady, isFalse);
    });

    test('a voiced phrase is ready until its text changes', () {
      final voiced = const PhraseDraft(id: 'p', text: 'Hello').withAudio(_audio);

      expect(voiced.isReady, isTrue);
      expect(voiced.withText(' Hello ').isReady, isTrue);
      expect(voiced.withText('Hello!').needsVoice, isTrue);
    });

    test('an empty phrase neither needs a voice nor is ready', () {
      const draft = PhraseDraft(id: 'p', text: '  ');

      expect(draft.needsVoice, isFalse);
      expect(draft.isReady, isFalse);
    });

    test('a new voice-over replaces the story range', () {
      final fromStory = PhraseDraft.fromPhrase(
        const Phrase(
          id: 'p',
          text: 'Hi',
          audioId: 'story',
          durationMs: 500,
          startMs: 1000,
          endMs: 1500,
          sourceLessonId: 'l1',
        ),
      );

      final revoiced = fromStory.withText('Hi there').withAudio(_audio);

      expect(fromStory.isReady, isTrue);
      expect(revoiced.toPhrase().sourceLessonId, isNull);
      expect(revoiced.toPhrase().startMs, isNull);
      expect(revoiced.toPhrase().audioId, 'a1');
    });

    test('a translation edit keeps the other languages', () {
      const draft = PhraseDraft(id: 'p', translations: {'ru': 'Привет'});

      final edited = draft.withTranslation('de', 'Hallo');

      expect(edited.translations, {'ru': 'Привет', 'de': 'Hallo'});
    });
  });

  group('synthesisBatches', () {
    test('splits by the text count limit', () {
      final texts = List.generate(kMaxSynthesisBatchTexts + 1, (i) => '$i');

      expect(synthesisBatches(texts).map((b) => b.length), [
        kMaxSynthesisBatchTexts,
        1,
      ]);
    });

    test('splits by the character limit', () {
      final text = 'x' * kMaxPhraseChars;
      final texts = List.filled(7, text);

      expect(synthesisBatches(texts).map((b) => b.length), [6, 1]);
    });
  });

  group('SavePhraseSet', () {
    late FakeLessonRepository repository;
    late SavePhraseSet save;

    setUp(() {
      repository = FakeLessonRepository();
      save = SavePhraseSet(repository);
    });

    PhraseSetForm form(List<PhraseDraft> phrases, {String title = 'Set'}) =>
        PhraseSetForm(title: title, phrases: phrases, level: LessonLevel.a2);

    test('drops empty rows and saves the voiced ones', () async {
      final ready = const PhraseDraft(id: 'p', text: 'Hi').withAudio(_audio);

      final lesson = await save(
        form([ready, const PhraseDraft(id: 'empty')]),
      );

      expect(lesson.phrases.map((p) => p.id), ['p']);
    });

    test('refuses a phrase that still needs a voice-over', () {
      expect(
        () => save(form([const PhraseDraft(id: 'p', text: 'Hi')])),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('refuses an empty title and an empty set', () {
      final ready = const PhraseDraft(id: 'p', text: 'Hi').withAudio(_audio);

      expect(
        () => save(form([ready], title: '  ')),
        throwsA(isA<ValidationFailure>()),
      );
      expect(() => save(form(const [])), throwsA(isA<ValidationFailure>()));
    });
  });

  test('SynthesizePhrases voices in batches and keeps the order', () async {
    final repository = FakeLessonRepository();

    final uploads = await SynthesizePhrases(repository)(['A', 'B']);

    expect(repository.synthesized, [
      ['A', 'B'],
    ]);
    expect(uploads.map((u) => u.audioId), ['tts-0', 'tts-1']);
  });
}
