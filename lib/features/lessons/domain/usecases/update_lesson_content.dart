import '../../../../core/error/failures.dart';
import '../entities/audio_trim.dart';
import '../entities/lesson.dart';
import '../entities/segment_boundaries.dart';
import '../repositories/lesson_repository.dart';
import 'create_lesson.dart';

/// Lesson editing: title, text split, segment boundaries and trimming.
class UpdateLessonContent {
  const UpdateLessonContent(this._repository);

  final LessonRepository _repository;

  /// Rebuilds [lesson] from the new fields and passes it to the repository.
  Future<Lesson> call({
    required Lesson lesson,
    required String title,
    required String rawText,
    required List<int> boundaries,
    AudioTrim? trim,
    bool? isPublic,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ValidationFailure('Введите название урока');
    }
    final segmentTexts = CreateLesson.splitIntoSegments(rawText);
    if (segmentTexts.isEmpty) {
      throw const ValidationFailure('Текст не содержит ни одного куска');
    }
    final range = (trim ?? lesson.trim).clampedTo(lesson.durationMs);
    // A layout that lags behind the text is laid out again.
    final source = boundaries.length == segmentTexts.length + 1
        ? boundaries
        : SegmentBoundaries.resize(boundaries, segmentTexts.length, range);
    final updated = lesson
        // Without an explicit value the visibility stays unchanged.
        .copyWith(title: trimmedTitle, isPublic: isPublic)
        .withSegments(
          texts: segmentTexts,
          boundaries: SegmentBoundaries.normalize(source, range),
        );
    await _repository.updateLesson(updated, isPublic: isPublic);
    return updated;
  }
}
