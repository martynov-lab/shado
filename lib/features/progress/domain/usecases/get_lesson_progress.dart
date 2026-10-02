import '../../../settings/domain/services/completion_threshold_service.dart';
import '../progress_math.dart';
import '../repositories/progress_repository.dart';

/// Share of the lesson already practised, from `0` to `1`.
class GetLessonProgress {
  const GetLessonProgress(this._repository, this._threshold);

  final ProgressRepository _repository;
  final CompletionThresholdService _threshold;

  Future<double> call({
    required String lessonId,
    required int segmentCount,
  }) async {
    final reps = await _repository.readReps(lessonId);
    final target = await _threshold.load();
    return lessonProgressFraction(reps, segmentCount, target);
  }
}
