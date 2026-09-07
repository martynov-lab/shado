import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_tts.dart';

/// Fake repository remembering the text the voice-over was called with.
class _FakeRepository implements LessonRepository {
  String? lastText;
  String? lastVoice;
  String? lastAccent;

  @override
  Future<AudioUpload> synthesizeTts({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  }) async {
    lastText = text;
    lastVoice = voice;
    lastAccent = accent;
    return const AudioUpload(audioId: 'tts', durationMs: 1000, sizeBytes: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('SynthesizeTts.prepareText', () {
    test('strips segment separators and collapses spaces', () {
      expect(
        SynthesizeTts.prepareText('Hello there. |  How are you?  '),
        'Hello there. How are you?',
      );
    });

    test('empty text and separators alone give an empty string', () {
      expect(SynthesizeTts.prepareText('  |  | '), isEmpty);
    });
  });

  group('SynthesizeTts.call', () {
    test('empty text fails before the server is called', () {
      final repository = _FakeRepository();

      expect(
        () => SynthesizeTts(repository).call(text: '   |  '),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.lastText, isNull);
    });

    test('text that is too long fails before the server is called', () {
      final repository = _FakeRepository();

      expect(
        () => SynthesizeTts(repository).call(text: 'a' * 2001),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.lastText, isNull);
    });

    test('the prepared text without separators goes to the server', () async {
      final repository = _FakeRepository();

      await SynthesizeTts(repository).call(text: 'One | Two');

      expect(repository.lastText, 'One Two');
    });

    test('the chosen voice and accent reach the repository', () async {
      final repository = _FakeRepository();

      await SynthesizeTts(
        repository,
      ).call(text: 'One', voice: 'Kore', accent: 'AU');

      expect(repository.lastVoice, 'Kore');
      expect(repository.lastAccent, 'AU');
    });
  });
}
