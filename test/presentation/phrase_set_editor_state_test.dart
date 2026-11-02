import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/phrase_draft.dart';
import 'package:shado/features/lessons/presentation/screens/phrase_set_editor/phrase_set_editor_state.dart';

const _audio = AudioUpload(audioId: 'a', durationMs: 900, sizeBytes: 1);

void main() {
  final voiced = const PhraseDraft(id: 'p1', text: 'Hi').withAudio(_audio);
  final ready = PhraseSetEditorState(
    title: 'Set',
    level: LessonLevel.a2,
    accent: 'US',
    phrases: [voiced],
  );

  test('only phrases with text and no translation need translating', () {
    final state = ready.copyWith(
      phrases: [
        voiced.withTranslation('ru', 'Привет'),
        const PhraseDraft(id: 'p2', text: 'Bye'),
        const PhraseDraft(id: 'p3'),
      ],
    );

    expect(state.missingTranslations('ru').map((p) => p.id), ['p2']);
    expect(state.missingTranslations('de').map((p) => p.id), ['p1', 'p2']);
  });

  test('a voiced set with a title and level can be saved', () {
    expect(ready.canSave(needsAccent: true), isTrue);
  });

  test('a phrase waiting for its voice-over blocks saving', () {
    final state = ready.updatePhrase('p1', (p) => p.withText('Hi there'));

    expect(state.toVoice.map((p) => p.id), ['p1']);
    expect(state.canSave(needsAccent: true), isFalse);
  });

  test('a missing accent blocks saving only for languages with accents', () {
    final noAccent = PhraseSetEditorState(
      title: 'Set',
      level: LessonLevel.a2,
      phrases: [voiced],
    );

    expect(noAccent.canSave(needsAccent: true), isFalse);
    expect(noAccent.canSave(needsAccent: false), isTrue);
  });

  test('saving is blocked while a voice-over runs', () {
    expect(ready.copyWith(isVoicing: true).canSave(needsAccent: true), isFalse);
  });
}
