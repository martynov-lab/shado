import '../repositories/lesson_repository.dart';

/// Длительность выбранного аудиофайла до создания урока: без неё нельзя
/// показать волну и расставить границы на экране создания.
class GetAudioDuration {
  const GetAudioDuration(this._repository);

  final LessonRepository _repository;

  Future<int> call(String audioPath) =>
      _repository.resolveAudioDurationMs(audioPath);
}
