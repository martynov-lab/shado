import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/usecases/create_lesson.dart';

void main() {
  group('CreateLesson.splitIntoSegments', () {
    test('splits the text on the separator and trims spaces', () {
      final parts = CreateLesson.splitIntoSegments(
        '  Hello there. |  How are you?  | Fine, thanks.',
      );

      expect(parts, [
        'Hello there.',
        'How are you?',
        'Fine, thanks.',
      ]);
    });

    test('drops empty segments', () {
      expect(
        CreateLesson.splitIntoSegments('One || Two |   | '),
        ['One', 'Two'],
      );
    });

    test('text without a separator gives one segment', () {
      expect(CreateLesson.splitIntoSegments('Single one'), ['Single one']);
    });

    test('empty text gives no segments', () {
      expect(CreateLesson.splitIntoSegments('   |  '), isEmpty);
    });
  });
}
