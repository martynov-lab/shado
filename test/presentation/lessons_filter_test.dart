import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_controller.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_filter.dart';

Lesson _lesson({
  required String id,
  required String title,
  Topic? topic,
  LessonLevel? level,
}) => Lesson(
  id: id,
  title: title,
  audioPath: 'audio',
  durationMs: 1000,
  createdAt: DateTime.utc(2020),
  segments: const [Segment(index: 0, text: 'x', startMs: 0, endMs: 1000)],
  topic: topic,
  level: level,
);

/// Подменяет источник данных списка, не ходя в сеть и БД.
class _FakeLessonsController extends LessonsController {
  _FakeLessonsController(this.items);

  final List<Lesson> items;

  @override
  Future<List<Lesson>> build() async => items;
}

void main() {
  const podcasts = Topic(id: 'topic-1', name: 'Подкасты');
  const dialogs = Topic(id: 'topic-2', name: 'Диалоги');

  final lessons = [
    _lesson(id: '1', title: 'Six-Minute English: Sleep', topic: podcasts, level: LessonLevel.b1),
    _lesson(id: '2', title: 'Everyday small talk', topic: dialogs, level: LessonLevel.a2),
    _lesson(id: '3', title: 'Deep sleep habits', topic: podcasts, level: LessonLevel.c1),
  ];

  group('LessonsFilter.matches', () {
    test('поиск по названию нечувствителен к регистру', () {
      const filter = LessonsFilter(query: 'sleep');
      expect(filter.matches(lessons[0]), isTrue);
      expect(filter.matches(lessons[2]), isTrue);
      expect(filter.matches(lessons[1]), isFalse);
    });

    test('фильтр по теме оставляет только выбранные', () {
      final filter = LessonsFilter(topicIds: {podcasts.id});
      expect(filter.matches(lessons[0]), isTrue);
      expect(filter.matches(lessons[1]), isFalse);
    });

    test('фильтр по уровню оставляет только выбранные', () {
      const filter = LessonsFilter(levels: {LessonLevel.a2});
      expect(filter.matches(lessons[1]), isTrue);
      expect(filter.matches(lessons[0]), isFalse);
    });

    test('группы фильтров складываются через И', () {
      final filter = LessonsFilter(
        query: 'sleep',
        topicIds: {podcasts.id},
        levels: {LessonLevel.c1},
      );
      expect(filter.matches(lessons[2]), isTrue);
      expect(filter.matches(lessons[0]), isFalse);
    });
  });

  group('lessonsFilterProvider', () {
    test('toggle добавляет и убирает значение', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(lessonsFilterProvider.notifier);

      notifier.toggleTopic(podcasts.id);
      expect(container.read(lessonsFilterProvider).topicIds, {podcasts.id});

      notifier.toggleTopic(podcasts.id);
      expect(container.read(lessonsFilterProvider).topicIds, isEmpty);
    });

    test('clearFilters очищает выбор, но не поиск', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(lessonsFilterProvider.notifier);

      notifier.setQuery('sleep');
      notifier.toggleLevel(LessonLevel.b1);
      notifier.clearFilters();

      final filter = container.read(lessonsFilterProvider);
      expect(filter.levels, isEmpty);
      expect(filter.query, 'sleep');
    });
  });

  group('filteredLessonsProvider', () {
    Future<ProviderContainer> pump() async {
      final container = ProviderContainer(
        overrides: [
          lessonsControllerProvider.overrideWith(
            () => _FakeLessonsController(lessons),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(lessonsControllerProvider.future);
      return container;
    }

    test('без фильтров отдаёт весь список', () async {
      final container = await pump();
      final result = container.read(filteredLessonsProvider).value!;
      expect(result, hasLength(3));
    });

    test('поиск сужает список', () async {
      final container = await pump();
      container.read(lessonsFilterProvider.notifier).setQuery('small talk');
      final result = container.read(filteredLessonsProvider).value!;
      expect(result.map((lesson) => lesson.id), ['2']);
    });

    test('фильтр по уровню сужает список', () async {
      final container = await pump();
      container.read(lessonsFilterProvider.notifier).toggleLevel(LessonLevel.b1);
      final result = container.read(filteredLessonsProvider).value!;
      expect(result.map((lesson) => lesson.id), ['1']);
    });
  });
}
