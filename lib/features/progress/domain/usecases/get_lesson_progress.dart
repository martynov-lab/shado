import '../progress_math.dart';
import '../repositories/progress_repository.dart';

/// Share of the lesson already learned, from `0` to `1`.
class GetLessonProgress {
  const GetLessonProgress(this._repository);

  final ProgressRepository _repository;

  Future<double> call({
    required String lessonId,
    required List<String> itemKeys,
  }) async {
    final stars = await _repository.readStars(lessonId);
    return lessonProgressFraction(stars, itemKeys);
  }
}
