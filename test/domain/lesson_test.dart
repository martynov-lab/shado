import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';

void main() {
  Lesson buildLesson({int durationMs = 9000, int count = 3}) {
    return Lesson.withEvenBoundaries(
      id: 'lesson-1',
      title: 'Урок',
      audioPath: '/audio/lesson-1.mp3',
      durationMs: durationMs,
      createdAt: DateTime.utc(2026, 1, 1),
      segmentTexts: [for (var i = 0; i < count; i++) 'Кусок $i'],
    );
  }

  group('Lesson.withEvenBoundaries', () {
    test('расставляет границы равномерно и встык', () {
      final lesson = buildLesson();

      expect(lesson.segments.map((s) => s.startMs), [0, 3000, 6000]);
      expect(lesson.segments.map((s) => s.endMs), [3000, 6000, 9000]);
      expect(lesson.boundaries, [0, 3000, 6000, 9000]);
    });

    test('нумерует куски с нуля и сохраняет порядок текстов', () {
      final lesson = buildLesson(count: 2);

      expect(lesson.segments.map((s) => s.index), [0, 1]);
      expect(lesson.segments.map((s) => s.text), ['Кусок 0', 'Кусок 1']);
    });

    test('приводит время создания к UTC', () {
      final lesson = Lesson.withEvenBoundaries(
        id: 'lesson-2',
        title: 'Урок',
        audioPath: '/audio/lesson-2.mp3',
        durationMs: 1000,
        createdAt: DateTime(2026, 1, 1),
        segmentTexts: const ['Кусок'],
      );

      expect(lesson.createdAt.isUtc, isTrue);
    });

    test('отвергает урок без кусков', () {
      expect(
        () => buildLesson(count: 0),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Lesson.withBoundaries', () {
    test('пересчитывает границы затронутых кусков', () {
      final updated = buildLesson().withBoundaries([0, 1000, 6000, 9000]);

      expect(updated.segments[0].endMs, 1000);
      expect(updated.segments[1].startMs, 1000);
      expect(updated.segments[1].endMs, 6000);
      expect(updated.segments.map((s) => s.text), [
        'Кусок 0',
        'Кусок 1',
        'Кусок 2',
      ]);
    });

    test('требует ровно N + 1 границу', () {
      expect(
        () => buildLesson().withBoundaries([0, 3000, 9000]),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('отвергает границы не по возрастанию', () {
      expect(
        () => buildLesson().withBoundaries([0, 6000, 3000, 9000]),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Lesson.withSegments', () {
    test('меняет число кусков вместе с границами', () {
      final updated = buildLesson().withSegments(
        texts: const ['Один', 'Два'],
        boundaries: const [0, 4000, 9000],
      );

      expect(updated.segmentCount, 2);
      expect(updated.segments.map((s) => s.text), ['Один', 'Два']);
      expect(updated.segments.map((s) => s.index), [0, 1]);
      expect(updated.boundaries, [0, 4000, 9000]);
    });

    test('не трогает аудио и метаданные урока', () {
      final lesson = buildLesson();
      final updated = lesson.withSegments(
        texts: const ['Один'],
        boundaries: const [0, 9000],
      );

      expect(updated.id, lesson.id);
      expect(updated.audioPath, lesson.audioPath);
      expect(updated.durationMs, lesson.durationMs);
      expect(updated.createdAt, lesson.createdAt);
    });

    test('требует границу на каждый стык', () {
      expect(
        () => buildLesson().withSegments(
          texts: const ['Один', 'Два'],
          boundaries: const [0, 9000],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
