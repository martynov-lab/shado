import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/usecases/create_lesson.dart';

void main() {
  group('CreateLesson.splitIntoSegments', () {
    test('режет текст по разделителю и обрезает пробелы', () {
      final parts = CreateLesson.splitIntoSegments(
        '  Hello there. |  How are you?  | Fine, thanks.',
      );

      expect(parts, [
        'Hello there.',
        'How are you?',
        'Fine, thanks.',
      ]);
    });

    test('выбрасывает пустые куски', () {
      expect(
        CreateLesson.splitIntoSegments('One || Two |   | '),
        ['One', 'Two'],
      );
    });

    test('текст без разделителя даёт один кусок', () {
      expect(CreateLesson.splitIntoSegments('Single one'), ['Single one']);
    });

    test('пустой текст не даёт кусков', () {
      expect(CreateLesson.splitIntoSegments('   |  '), isEmpty);
    });
  });
}
