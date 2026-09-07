import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';

void main() {
  Lesson buildLesson({int durationMs = 9000, int count = 3}) {
    return Lesson.withEvenBoundaries(
      id: 'lesson-1',
      title: 'Lesson',
      audioPath: '/audio/lesson-1.mp3',
      durationMs: durationMs,
      createdAt: DateTime.utc(2026, 1, 1),
      segmentTexts: [for (var i = 0; i < count; i++) 'Segment $i'],
    );
  }

  group('Lesson.withEvenBoundaries', () {
    test('places boundaries evenly and back to back', () {
      final lesson = buildLesson();

      expect(lesson.segments.map((s) => s.startMs), [0, 3000, 6000]);
      expect(lesson.segments.map((s) => s.endMs), [3000, 6000, 9000]);
      expect(lesson.boundaries, [0, 3000, 6000, 9000]);
    });

    test('numbers segments from zero and keeps the order of texts', () {
      final lesson = buildLesson(count: 2);

      expect(lesson.segments.map((s) => s.index), [0, 1]);
      expect(lesson.segments.map((s) => s.text), ['Segment 0', 'Segment 1']);
    });

    test('converts the creation time to UTC', () {
      final lesson = Lesson.withEvenBoundaries(
        id: 'lesson-2',
        title: 'Lesson',
        audioPath: '/audio/lesson-2.mp3',
        durationMs: 1000,
        createdAt: DateTime(2026, 1, 1),
        segmentTexts: const ['Segment'],
      );

      expect(lesson.createdAt.isUtc, isTrue);
    });

    test('rejects a lesson without segments', () {
      expect(
        () => buildLesson(count: 0),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Lesson.withBoundaries', () {
    test('recomputes the boundaries of the affected segments', () {
      final updated = buildLesson().withBoundaries([0, 1000, 6000, 9000]);

      expect(updated.segments[0].endMs, 1000);
      expect(updated.segments[1].startMs, 1000);
      expect(updated.segments[1].endMs, 6000);
      expect(updated.segments.map((s) => s.text), [
        'Segment 0',
        'Segment 1',
        'Segment 2',
      ]);
    });

    test('requires exactly N + 1 boundaries', () {
      expect(
        () => buildLesson().withBoundaries([0, 3000, 9000]),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects boundaries that are not increasing', () {
      expect(
        () => buildLesson().withBoundaries([0, 6000, 3000, 9000]),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Lesson.withSegments', () {
    test('changes the segment count along with the boundaries', () {
      final updated = buildLesson().withSegments(
        texts: const ['One', 'Two'],
        boundaries: const [0, 4000, 9000],
      );

      expect(updated.segmentCount, 2);
      expect(updated.segments.map((s) => s.text), ['One', 'Two']);
      expect(updated.segments.map((s) => s.index), [0, 1]);
      expect(updated.boundaries, [0, 4000, 9000]);
    });

    test('leaves the audio and the lesson metadata alone', () {
      final lesson = buildLesson();
      final updated = lesson.withSegments(
        texts: const ['One'],
        boundaries: const [0, 9000],
      );

      expect(updated.id, lesson.id);
      expect(updated.audioPath, lesson.audioPath);
      expect(updated.durationMs, lesson.durationMs);
      expect(updated.createdAt, lesson.createdAt);
    });

    test('requires a boundary at every joint', () {
      expect(
        () => buildLesson().withSegments(
          texts: const ['One', 'Two'],
          boundaries: const [0, 9000],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
