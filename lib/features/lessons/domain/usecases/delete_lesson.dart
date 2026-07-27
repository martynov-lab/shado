import '../repositories/lesson_repository.dart';

/// Удаление урока вместе с его локальным аудио.
class DeleteLesson {
  const DeleteLesson(this._repository);

  final LessonRepository _repository;

  Future<void> call(String id) => _repository.deleteLesson(id);
}
