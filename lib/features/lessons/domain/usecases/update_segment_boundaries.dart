import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
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
  /// [kMinSegmentGapMs].
  static List<int> normalize(List<int> boundaries, int durationMs) {
    if (boundaries.length < 2) {
      throw const ValidationFailure('Границ должно быть не меньше двух');
    }
    final result = List<int>.of(boundaries);
    result[0] = 0;
    result[result.length - 1] = durationMs;
    for (var i = 1; i < result.length - 1; i++) {
      final lowerLimit = result[i - 1] + kMinSegmentGapMs;
      // На очень коротком аудио минимальный зазор может не поместиться —
      // тогда границы просто идут подряд с шагом в 1 мс.
      final upperLimit = math.max(
        lowerLimit,
        durationMs - kMinSegmentGapMs * (result.length - 1 - i),
      );
      result[i] = result[i].clamp(lowerLimit, upperLimit);
    }
    return result;
  }
}
