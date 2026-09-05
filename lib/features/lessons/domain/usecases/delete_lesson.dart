import '../repositories/lesson_repository.dart';

/// Deletes a lesson together with its local audio.
class DeleteLesson {
  const DeleteLesson(this._repository);

  final LessonRepository _repository;

  Future<void> call(String id) => _repository.deleteLesson(id);
}
