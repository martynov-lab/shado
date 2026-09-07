import '../repositories/lesson_repository.dart';

/// Pulls changes made since the previous sync.
class SyncLessons {
  const SyncLessons(this._repository);

  final LessonRepository _repository;

  /// [language] is the studied language the delta belongs to.
  Future<void> call({String language = ''}) =>
      _repository.syncLessons(language: language);
}
