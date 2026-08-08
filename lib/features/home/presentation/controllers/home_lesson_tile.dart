import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/widgets/lesson_labels.dart';

/// Урок в превью главного экрана: заголовок, подзаголовок и длительность,
/// приведённые из [Lesson]. Держит [id] и [segmentCount] — по ним карточка
/// «Продолжить» берёт долю пройденности.
class HomeLessonTile {
  const HomeLessonTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.segmentCount,
  });

  factory HomeLessonTile.from(Lesson lesson) => HomeLessonTile(
    id: lesson.id,
    title: lesson.title,
    subtitle: lessonSubtitle(lesson),
    time: _duration(lesson),
    segmentCount: lesson.segmentCount,
  );

  final String id;
  final String title;
  final String subtitle;

  /// Длительность урока «m:ss».
  final String time;

  final int segmentCount;

  /// «m:ss» по отрезку файла, попавшему в урок.
  static String _duration(Lesson lesson) {
    final total = lesson.trim.durationMs.clamp(0, 1 << 62);
    final minutes = total ~/ 60000;
    final seconds = (total % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
