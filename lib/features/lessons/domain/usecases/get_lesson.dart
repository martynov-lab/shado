import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

/// Один урок по идентификатору.
class GetLesson {
  const GetLesson(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call(String id) async {
    final lesson = await _repository.getLesson(id);
    if (lesson == null) {
      throw NotFoundFailure('Урок $id не найден');
    }
    return lesson;
  }
}
