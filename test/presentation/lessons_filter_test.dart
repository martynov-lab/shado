import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/folder.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/library_root.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_controller.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_filter.dart';
import 'package:shado/features/lessons/presentation/controllers/library_controller.dart';

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

/// Корень библиотеки без сети: папки и уроки вне папок, как их отдаёт
/// `/v1/library`.
class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.root);

  final LibraryRoot root;

  @override
  Future<LibraryRoot> build() async => root;
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

  // §6.3: без поиска экран показывает корень с сервера, а с поиском становится
  // плоским — по всему каталогу, включая уроки, разложенные по папкам.
  group('главный экран: корень и поиск', () {
    final folder = Folder(
      id: 'f1',
      title: 'Sleep podcasts',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      version: 1,
      lessonCount: 2,
    );

    // Корень: папка и один свободный урок. Уроки 1 и 3 лежат в папке, поэтому
    // сервер их сюда не кладёт.
    final root = LibraryRoot(folders: [folder], lessons: [lessons[1]]);

    Future<ProviderContainer> pump() async {
      final container = ProviderContainer(
        overrides: [
          lessonsControllerProvider.overrideWith(
            () => _FakeLessonsController(lessons),
          ),
          libraryControllerProvider.overrideWith(
            () => _FakeLibraryController(root),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(libraryControllerProvider.future);
      await container.read(lessonsControllerProvider.future);
      return container;
    }

    test('без поиска показываем корень, а не весь кеш', () async {
      final container = await pump();

      expect(container.read(visibleLessonsProvider).map((l) => l.id), ['2']);
      expect(container.read(visibleFoldersProvider), [folder]);
    });

    test('поиск находит и урок внутри папки', () async {
      final container = await pump();
      container.read(lessonsFilterProvider.notifier).setQuery('sleep');

      // Урок 1 в корень не приходил, но поиск идёт по каталогу и находит его.
      expect(container.read(visibleLessonsProvider).map((l) => l.id), [
        '1',
        '3',
      ]);
      // Папка подходит по названию — её оставляем.
      expect(container.read(visibleFoldersProvider), [folder]);
    });

    test('фильтр по категории прячет папки: у них нет уровня', () async {
      final container = await pump();
      container.read(lessonsFilterProvider.notifier).toggleLevel(LessonLevel.c1);

      expect(container.read(visibleLessonsProvider).map((l) => l.id), ['3']);
      expect(container.read(visibleFoldersProvider), isEmpty);
    });
  });
}
