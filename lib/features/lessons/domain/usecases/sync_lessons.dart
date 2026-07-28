import '../repositories/lesson_repository.dart';

/// Подтягивает с сервера изменения с прошлого раза: на старте и по
/// pull-to-refresh.
class SyncLessons {
  const SyncLessons(this._repository);

  final LessonRepository _repository;

  Future<void> call() => _repository.syncLessons();
}
