import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_download.dart';

/// A lesson in a list together with what its card shows.
class LessonListItem {
  const LessonListItem({
    required this.lesson,
    required this.progress,
    required this.canModify,
    this.download = const NotDownloaded(),
    this.isAvailable = true,
    this.canToggleDownload = true,
  });

  final Lesson lesson;

  /// How much of the lesson is done, `0..1`.
  final double progress;

  /// Whether the user may edit and delete the lesson.
  final bool canModify;

  /// Whether the lesson is kept on the device for offline study.
  final LessonDownload download;

  /// Whether the lesson can be opened; offline only with its audio cached.
  final bool isAvailable;

  /// Offline a lesson can't be downloaded, only its download removed.
  final bool canToggleDownload;
}
