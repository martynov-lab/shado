import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/lesson_routes.dart';
import '../../../lessons/presentation/widgets/lesson_labels.dart';

/// Lesson preview tile on the home screen, mapped from [Lesson].
class HomeLessonTile {
  const HomeLessonTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.itemKeys,
    required this.route,
  });

  factory HomeLessonTile.from(Lesson lesson) => HomeLessonTile(
    id: lesson.id,
    title: lesson.title,
    subtitle: lessonSubtitle(lesson),
    time: _duration(lesson),
    itemKeys: lesson.itemKeys,
    route: lessonRoute(lesson),
  );

  final String id;
  final String title;
  final String subtitle;

  /// Lesson duration as `m:ss`.
  final String time;

  /// Rating keys of the lesson items, for the progress bar.
  final List<String> itemKeys;

  /// Where the lesson opens: the story player or the phrase cards.
  final String route;

  /// `m:ss` for the file range that made it into the lesson.
  static String _duration(Lesson lesson) {
    final total = lesson.trim.durationMs.clamp(0, 1 << 62);
    final minutes = total ~/ 60000;
    final seconds = (total % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
