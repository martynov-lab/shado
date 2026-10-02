import '../../../domain/entities/lesson.dart';

/// A lesson in a list together with what its card shows.
class LessonListItem {
  const LessonListItem({
    required this.lesson,
    required this.progress,
    required this.canModify,
  });

  final Lesson lesson;

  /// How much of the lesson is done, `0..1`.
  final double progress;

  /// Whether the user may edit and delete the lesson.
  final bool canModify;
}
