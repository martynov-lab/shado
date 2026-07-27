import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

/// Список всех уроков для главного экрана.
class GetLessons {
  const GetLessons(this._repository);

  final LessonRepository _repository;

  Future<List<Lesson>> call() => _repository.getLessons();
}
