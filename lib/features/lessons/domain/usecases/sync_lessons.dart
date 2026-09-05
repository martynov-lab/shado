import '../repositories/lesson_repository.dart';

/// Pulls changes made since the previous sync.
class SyncLessons {
  const SyncLessons(this._repository);

  final LessonRepository _repository;

  Future<void> call() => _repository.syncLessons();
}
