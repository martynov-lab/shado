import 'folder.dart';
import 'lesson.dart';
import 'lesson_category.dart';

/// How long a lesson counts as new after being added.
const Duration kNewLessonWindow = Duration(days: 7);

/// Whether the lesson was added recently.
bool lessonIsNew(Lesson lesson) =>
    DateTime.now().toUtc().difference(lesson.createdAt) < kNewLessonWindow;

/// Lesson status in the list filter; [inProgress] and [done] do not filter
/// anything yet.
enum LessonFilterStatus {
  fresh('New'),
  inProgress('In progress'),
  done('Completed');

  const LessonFilterStatus(this.label);

  final String label;
}

/// Search query and the selected filter sets of the lesson list.
class LessonsFilter {
  const LessonsFilter({
    this.query = '',
    this.topicIds = const {},
    this.levels = const {},
    this.accents = const {},
    this.statuses = const {},
    this.onlyPrivate = false,
  });

  final String query;
  final Set<String> topicIds;
  final Set<LessonLevel> levels;

  /// Accent codes of the current language; empty for languages without them.
  final Set<String> accents;

  final Set<LessonFilterStatus> statuses;

  /// Show private lessons only.
  final bool onlyPrivate;

  /// Whether the filter is empty: no query and no selected values.
  bool get isEmpty =>
      query.isEmpty &&
      topicIds.isEmpty &&
      levels.isEmpty &&
      accents.isEmpty &&
      statuses.isEmpty &&
      !onlyPrivate;

  /// How many filters are selected, excluding the search query.
  int get activeCount =>
      topicIds.length +
      levels.length +
      accents.length +
      statuses.length +
      (onlyPrivate ? 1 : 0);

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
    if (accents.isNotEmpty &&
        !(lesson.accent != null && accents.contains(lesson.accent))) {
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

  /// Lessons of [lessons] that pass the filter.
  List<Lesson> apply(List<Lesson> lessons) => isEmpty
      ? lessons
      : [
          for (final lesson in lessons)
            if (matches(lesson)) lesson,
        ];

  /// Without a query or filters the screen shows the library root; with them
  /// it searches the whole [catalog], lessons inside folders included.
  List<Lesson> visibleLessons({
    required List<Lesson> catalog,
    required List<Lesson> rootLessons,
  }) => isEmpty ? rootLessons : apply(catalog);

  /// Folders are matched by title and hidden while category filters are on:
  /// they have no topic or level.
  List<Folder> visibleFolders(List<Folder> folders) {
    if (activeCount > 0) return const [];
    if (query.isEmpty) return folders;
    final lowered = query.toLowerCase();
    return [
      for (final folder in folders)
        if (folder.title.toLowerCase().contains(lowered)) folder,
    ];
  }

  LessonsFilter withQuery(String query) => copyWith(query: query);

  LessonsFilter toggleTopic(String id) =>
      copyWith(topicIds: _toggled(topicIds, id));

  LessonsFilter toggleLevel(LessonLevel level) =>
      copyWith(levels: _toggled(levels, level));

  LessonsFilter toggleAccent(String code) =>
      copyWith(accents: _toggled(accents, code));

  LessonsFilter toggleStatus(LessonFilterStatus status) =>
      copyWith(statuses: _toggled(statuses, status));

  LessonsFilter toggleOnlyPrivate() => copyWith(onlyPrivate: !onlyPrivate);

  /// Drops the selected filters but keeps the search query.
  LessonsFilter cleared() => LessonsFilter(query: query);

  LessonsFilter copyWith({
    String? query,
    Set<String>? topicIds,
    Set<LessonLevel>? levels,
    Set<String>? accents,
    Set<LessonFilterStatus>? statuses,
    bool? onlyPrivate,
  }) {
    return LessonsFilter(
      query: query ?? this.query,
      topicIds: topicIds ?? this.topicIds,
      levels: levels ?? this.levels,
      accents: accents ?? this.accents,
      statuses: statuses ?? this.statuses,
      onlyPrivate: onlyPrivate ?? this.onlyPrivate,
    );
  }

  static Set<T> _toggled<T>(Set<T> set, T value) {
    final next = Set<T>.of(set);
    if (!next.remove(value)) next.add(value);
    return next;
  }
}
