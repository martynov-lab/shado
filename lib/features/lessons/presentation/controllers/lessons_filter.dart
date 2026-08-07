import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import 'lessons_controller.dart';

/// Сколько урок считается «новым» с момента загрузки — для метки «New» и
/// фильтра по статусу.
const Duration kNewLessonWindow = Duration(days: 7);

/// Загружен недавно и ещё не примелькался.
bool lessonIsNew(Lesson lesson) =>
    DateTime.now().toUtc().difference(lesson.createdAt) < kNewLessonWindow;

/// Статус урока в фильтре списка.
///
/// [fresh] считается по дате загрузки. [inProgress] и [done] опираются на
/// прогресс разбора, которого пока нет в данных, — поэтому они ничего не
/// отбирают (см. [LessonsFilter.matches]). Оставлены ради полноты набора из
/// макета: заработают, когда появится отслеживание прогресса.
enum LessonFilterStatus {
  fresh('Новые'),
  inProgress('В процессе'),
  done('Завершённые');

  const LessonFilterStatus(this.label);

  final String label;
}

/// Что показываем в списке уроков: строка поиска и наборы выбранных фильтров.
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

  /// Показывать только приватные уроки. Сервер отдаёт приватными лишь свои,
  /// поэтому это и есть «Мои приватные».
  final bool onlyPrivate;

  /// Ни поиск, ни фильтры не заданы — список показываем целиком.
  bool get isEmpty =>
      query.isEmpty &&
      topicIds.isEmpty &&
      levels.isEmpty &&
      statuses.isEmpty &&
      !onlyPrivate;

  /// Сколько фильтров выбрано (без строки поиска) — для бейджа «N» и кнопки
  /// «Сбросить».
  int get activeCount =>
      topicIds.length + levels.length + statuses.length + (onlyPrivate ? 1 : 0);

  /// Проходит ли урок сквозь текущие фильтры. Внутри группы — ИЛИ (любой из
  /// выбранных), между группами — И.
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
    // Прогресс разбора не отслеживается — эти статусы пока пусты.
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

/// Правит фильтр списка уроков. Живёт отдельно от [LessonsController]: тот
/// отвечает за данные, а фильтр — за то, что из них показать.
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

  /// Сбрасывает фильтры, но не строку поиска — крестик у поля чистит её сам.
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

/// Список уроков после применения поиска и фильтров. Сохраняет состояние
/// загрузки/ошибки исходного [lessonsControllerProvider].
final filteredLessonsProvider = Provider<AsyncValue<List<Lesson>>>((ref) {
  final lessons = ref.watch(lessonsControllerProvider);
  final filter = ref.watch(lessonsFilterProvider);
  if (filter.isEmpty) return lessons;
  return lessons.whenData(
    (items) => [for (final lesson in items) if (filter.matches(lesson)) lesson],
  );
});
