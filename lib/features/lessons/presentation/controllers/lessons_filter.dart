import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import 'lessons_controller.dart';
import 'library_controller.dart';

/// How long a lesson counts as new after being added.
const Duration kNewLessonWindow = Duration(days: 7);

/// Whether the lesson was added recently.
bool lessonIsNew(Lesson lesson) =>
    DateTime.now().toUtc().difference(lesson.createdAt) < kNewLessonWindow;

/// Lesson status in the list filter; [inProgress] and [done] do not filter
/// anything yet.
enum LessonFilterStatus {
  fresh('Новые'),
  inProgress('В процессе'),
  done('Завершённые');

  const LessonFilterStatus(this.label);

  final String label;
}

/// Search query and the selected filter sets of the lesson list.
class LessonsFilter {
  const LessonsFilter({
    this.query = '',
    this.topicIds = const {},
    this.levels = const {},
    this.statuses = const {},
    this.onlyPrivate = false,
  });

  final String query;
  final Set<String> topicIds;
  final Set<LessonLevel> levels;
  final Set<LessonFilterStatus> statuses;

  /// Show private lessons only.
  final bool onlyPrivate;

  /// Whether the filter is empty: no query and no selected values.
  bool get isEmpty =>
      query.isEmpty &&
      topicIds.isEmpty &&
      levels.isEmpty &&
      statuses.isEmpty &&
      !onlyPrivate;

  /// How many filters are selected, excluding the search query.
  int get activeCount =>
      topicIds.length + levels.length + statuses.length + (onlyPrivate ? 1 : 0);

  /// Whether a lesson passes the filters: OR inside a group, AND across.
  bool matches(Lesson lesson) {
    if (query.isNotEmpty &&
        !lesson.title.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    if (topicIds.isNotEmpty &&
        !(lesson.topic != null && topicIds.contains(lesson.topic!.id))) {
      return false;
    }
    if (levels.isNotEmpty &&
        !(lesson.level != null && levels.contains(lesson.level))) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.any((s) => _hasStatus(lesson, s))) {
      return false;
    }
    if (onlyPrivate && lesson.isPublic) {
      return false;
    }
    return true;
  }

  bool _hasStatus(Lesson lesson, LessonFilterStatus status) => switch (status) {
    LessonFilterStatus.fresh => lessonIsNew(lesson),
    // Study progress is not tracked.
    LessonFilterStatus.inProgress => false,
    LessonFilterStatus.done => false,
  };

  LessonsFilter copyWith({
    String? query,
    Set<String>? topicIds,
    Set<LessonLevel>? levels,
    Set<LessonFilterStatus>? statuses,
    bool? onlyPrivate,
  }) {
    return LessonsFilter(
      query: query ?? this.query,
      topicIds: topicIds ?? this.topicIds,
      levels: levels ?? this.levels,
      statuses: statuses ?? this.statuses,
      onlyPrivate: onlyPrivate ?? this.onlyPrivate,
    );
  }
}

/// Edits the lesson list filter.
class LessonsFilterNotifier extends Notifier<LessonsFilter> {
  @override
  LessonsFilter build() => const LessonsFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleTopic(String id) =>
      state = state.copyWith(topicIds: _toggled(state.topicIds, id));

  void toggleLevel(LessonLevel level) =>
      state = state.copyWith(levels: _toggled(state.levels, level));

  void toggleStatus(LessonFilterStatus status) =>
      state = state.copyWith(statuses: _toggled(state.statuses, status));

  void toggleOnlyPrivate() =>
      state = state.copyWith(onlyPrivate: !state.onlyPrivate);

  /// Clears the filters without touching the search query.
  void clearFilters() => state = state.copyWith(
    topicIds: const {},
    levels: const {},
    statuses: const {},
    onlyPrivate: false,
  );

  Set<T> _toggled<T>(Set<T> set, T value) {
    final next = Set<T>.of(set);
    if (!next.remove(value)) next.add(value);
    return next;
  }
}

final lessonsFilterProvider =
    NotifierProvider<LessonsFilterNotifier, LessonsFilter>(
      LessonsFilterNotifier.new,
    );

/// Lesson list after search and filters.
final filteredLessonsProvider = Provider<AsyncValue<List<Lesson>>>((ref) {
  final lessons = ref.watch(lessonsControllerProvider);
  final filter = ref.watch(lessonsFilterProvider);
  if (filter.isEmpty) return lessons;
  return lessons.whenData(
    (items) => [for (final lesson in items) if (filter.matches(lesson)) lesson],
  );
});

/// Home screen lessons: the library root without filters, a flat catalog
/// listing with them.
final visibleLessonsProvider = Provider<List<Lesson>>((ref) {
  // The cache stays subscribed so search works right away.
  final catalog = ref.watch(filteredLessonsProvider).value ?? const [];
  final filter = ref.watch(lessonsFilterProvider);
  if (!filter.isEmpty) return catalog;
  return ref.watch(libraryControllerProvider).value?.lessons ?? const [];
});

/// Home screen folders: matched by title and hidden while category filters
/// are active.
final visibleFoldersProvider = Provider<List<Folder>>((ref) {
  final filter = ref.watch(lessonsFilterProvider);
  if (filter.activeCount > 0) return const [];
  final folders =
      ref.watch(libraryControllerProvider).value?.folders ?? const [];
  if (filter.query.isEmpty) return folders;
  final query = filter.query.toLowerCase();
  return [
    for (final folder in folders)
      if (folder.title.toLowerCase().contains(query)) folder,
  ];
});
