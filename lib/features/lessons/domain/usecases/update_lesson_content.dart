import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../entities/segment_boundaries.dart';
import '../repositories/lesson_repository.dart';
import 'create_lesson.dart';

/// Правка уже созданного урока: название, разбивка текста на куски и границы
/// этих кусков на аудио.
///
/// В отличие от `UpdateSegmentBoundaries` число кусков здесь может измениться,
/// поэтому урок пересобирается целиком. Аудио не трогаем.
class UpdateLessonContent {
  const UpdateLessonContent(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call({
    required String lessonId,
    required String title,
    required String rawText,
    required List<int> boundaries,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ValidationFailure('Введите название урока');
    }
    final segmentTexts = CreateLesson.splitIntoSegments(rawText);
    if (segmentTexts.isEmpty) {
      throw const ValidationFailure('Текст не содержит ни одного куска');
    }
    final lesson = await _repository.getLesson(lessonId);
    if (lesson == null) {
      throw NotFoundFailure('Урок $lessonId не найден');
    }
    // Разметка могла отстать от текста — тогда куски раскладываются заново.
    final source = boundaries.length == segmentTexts.length + 1
        ? boundaries
        : SegmentBoundaries.resize(
            boundaries,
            segmentTexts.length,
            lesson.durationMs,
          );
    final updated = lesson
        .copyWith(title: trimmedTitle)
        .withSegments(
          texts: segmentTexts,
          boundaries: SegmentBoundaries.normalize(source, lesson.durationMs),
        );
    await _repository.updateLesson(updated);
    return updated;
  }
}
