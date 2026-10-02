import '../../../domain/entities/lessons_filter.dart';

/// A filter group of the lesson list.
enum LessonFilterGroup {
  topic('Topic'),
  level('Level'),
  accent('Accent'),
  status('Status'),
  access('Access');

  const LessonFilterGroup(this.title);

  final String title;

  /// How many values of this group are selected in [filter].
  int countIn(LessonsFilter filter) => switch (this) {
    topic => filter.topicIds.length,
    level => filter.levels.length,
    accent => filter.accents.length,
    status => filter.statuses.length,
    access => filter.onlyPrivate ? 1 : 0,
  };
}
