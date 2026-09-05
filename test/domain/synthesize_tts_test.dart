import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_tts.dart';

/// Fake repository remembering the text the voice-over was called with.
class _FakeRepository implements LessonRepository {
  String? lastText;

  @override
  Future<AudioUpload> synthesizeTts({
    required String text,
    Object? cancel,
  }) async {
    lastText = text;
    return const AudioUpload(audioId: 'tts', durationMs: 1000, sizeBytes: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('SynthesizeTts.prepareText', () {
    test('убирает разделители сегментов и схлопывает пробелы', () {
      expect(
        SynthesizeTts.prepareText('Hello there. |  How are you?  '),
        'Hello there. How are you?',
      );
    });

    test('пустой текст и одни разделители дают пустую строку', () {
      expect(SynthesizeTts.prepareText('  |  | '), isEmpty);
    });
  });

  group('SynthesizeTts.call', () {
    test('пустой текст — ошибка до обращения к серверу', () {
      final repository = _FakeRepository();

      expect(
        () => SynthesizeTts(repository).call(text: '   |  '),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.lastText, isNull);
    });

    test('слишком длинный текст — ошибка до обращения к серверу', () {
      final repository = _FakeRepository();

      expect(
        () => SynthesizeTts(repository).call(text: 'a' * 2001),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.lastText, isNull);
    });

    test('на сервер уходит подготовленный текст без разделителей', () async {
      final repository = _FakeRepository();

      await SynthesizeTts(repository).call(text: 'One | Two');

      expect(repository.lastText, 'One Two');
    });
  });
}
