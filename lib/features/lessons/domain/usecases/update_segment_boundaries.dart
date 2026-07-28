import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../entities/segment_boundaries.dart';
import '../repositories/lesson_repository.dart';

/// Сохранение новых границ кусков после перетаскивания меток на волне.
///
/// Границы общие: для `N` кусков передаётся `N + 1` значение, крайние из
/// которых зафиксированы на `0` и `durationMs`.
class UpdateSegmentBoundaries {
  const UpdateSegmentBoundaries(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call({
    required String lessonId,
    required List<int> boundaries,
  }) async {
    final lesson = await _repository.getLesson(lessonId);
    if (lesson == null) {
      throw NotFoundFailure('Урок $lessonId не найден');
    }
    final normalized = normalize(boundaries, lesson.durationMs);
    final updated = lesson.withBoundaries(normalized);
    await _repository.updateLesson(updated);
    return updated;
  }

  /// Прижимает крайние границы к краям аудио и разводит соседние минимум на
  /// `kMinSegmentGapMs`.
  static List<int> normalize(List<int> boundaries, int durationMs) =>
      SegmentBoundaries.normalize(boundaries, durationMs);
}
