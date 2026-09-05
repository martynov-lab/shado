import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

/// All lessons for the home screen.
class GetLessons {
  const GetLessons(this._repository);

  final LessonRepository _repository;

  Future<List<Lesson>> call() => _repository.getLessons();
}
