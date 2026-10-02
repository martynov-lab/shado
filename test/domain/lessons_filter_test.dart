import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/folder.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/lessons_filter.dart';
import 'package:shado/features/lessons/domain/entities/library_root.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';

Lesson _lesson({
  required String id,
  required String title,
  Topic? topic,
  LessonLevel? level,
  String? accent,
}) => Lesson(
  id: id,
  title: title,
  audioPath: 'audio',
  durationMs: 1000,
  createdAt: DateTime.utc(2020),
  segments: const [Segment(index: 0, text: 'x', startMs: 0, endMs: 1000)],
  topic: topic,
  level: level,
  accent: accent,
);

void main() {
  const podcasts = Topic(id: 'topic-1', name: 'Podcasts');
  const dialogs = Topic(id: 'topic-2', name: 'Dialogues');

  final lessons = [
    _lesson(
      id: '1',
      title: 'Six-Minute English: Sleep',
      topic: podcasts,
      level: LessonLevel.b1,
      accent: 'UK',
    ),
    _lesson(
      id: '2',
      title: 'Everyday small talk',
      topic: dialogs,
      level: LessonLevel.a2,
      accent: 'AU',
    ),
    _lesson(
      id: '3',
      title: 'Deep sleep habits',
      topic: podcasts,
      level: LessonLevel.c1,
    ),
  ];

  group('LessonsFilter.matches', () {
    test('search by title is case insensitive', () {
      const filter = LessonsFilter(query: 'sleep');
      expect(filter.matches(lessons[0]), isTrue);
      expect(filter.matches(lessons[2]), isTrue);
      expect(filter.matches(lessons[1]), isFalse);
    });

    test('the topic filter keeps only the selected ones', () {
      final filter = LessonsFilter(topicIds: {podcasts.id});
      expect(filter.matches(lessons[0]), isTrue);
      expect(filter.matches(lessons[1]), isFalse);
    });

    test('the level filter keeps only the selected ones', () {
      const filter = LessonsFilter(levels: {LessonLevel.a2});
      expect(filter.matches(lessons[1]), isTrue);
      expect(filter.matches(lessons[0]), isFalse);
    });

    test('the accent filter keeps only the selected ones', () {
      const filter = LessonsFilter(accents: {'AU'});
      expect(filter.matches(lessons[1]), isTrue);
      expect(filter.matches(lessons[0]), isFalse);
      // A lesson of a language without accents never matches the filter.
      expect(filter.matches(lessons[2]), isFalse);
    });

    test('filter groups combine with AND', () {
      final filter = LessonsFilter(
        query: 'sleep',
        topicIds: {podcasts.id},
        levels: {LessonLevel.c1},
      );
      expect(filter.matches(lessons[2]), isTrue);
      expect(filter.matches(lessons[0]), isFalse);
    });
  });

  group('LessonsFilter changes', () {
    test('toggle adds and removes a value', () {
      final once = const LessonsFilter().toggleTopic(podcasts.id);
      expect(once.topicIds, equals({podcasts.id}));

      expect(once.toggleTopic(podcasts.id).topicIds, isEmpty);
    });

    test('cleared drops the selection but keeps the query', () {
      final filter = const LessonsFilter()
          .withQuery('sleep')
          .toggleLevel(LessonLevel.b1)
          .cleared();

      expect(filter.levels, isEmpty);
      expect(filter.query, equals('sleep'));
    });
  });

  group('LessonsFilter.apply', () {
    test('without filters it returns the whole list', () {
      expect(const LessonsFilter().apply(lessons), hasLength(3));
    });

    test('the query narrows the list', () {
      final result = const LessonsFilter(query: 'small talk').apply(lessons);
      expect(result.map((lesson) => lesson.id), equals(['2']));
    });

    test('the level filter narrows the list', () {
      final result = const LessonsFilter(
        levels: {LessonLevel.b1},
      ).apply(lessons);
      expect(result.map((lesson) => lesson.id), equals(['1']));
    });
  });

  // Without a query the screen shows the root, with one the whole catalog.
  group('home screen: root and search', () {
    final folder = Folder(
      id: 'f1',
      title: 'Sleep podcasts',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      version: 1,
      lessonCount: 2,
    );

    // The root holds a folder and one unfiled lesson; the rest are inside.
    final root = LibraryRoot(folders: [folder], lessons: [lessons[1]]);

    List<String> visibleIds(LessonsFilter filter) => [
      for (final lesson in filter.visibleLessons(
        catalog: lessons,
        rootLessons: root.lessons,
      ))
        lesson.id,
    ];

    test('without a query we show the root, not the whole cache', () {
      const filter = LessonsFilter();

      expect(visibleIds(filter), equals(['2']));
      expect(filter.visibleFolders(root.folders), equals([folder]));
    });

    test('search finds a lesson inside a folder too', () {
      const filter = LessonsFilter(query: 'sleep');

      // Lesson 1 is missing from the root, but search scans the whole catalog.
      expect(visibleIds(filter), equals(['1', '3']));
      // The folder matches by title and is kept.
      expect(filter.visibleFolders(root.folders), equals([folder]));
    });

    test('a category filter hides folders: they have no level', () {
      const filter = LessonsFilter(levels: {LessonLevel.c1});

      expect(visibleIds(filter), equals(['3']));
      expect(filter.visibleFolders(root.folders), isEmpty);
    });
  });
}
