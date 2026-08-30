import '../entities/tts_quota.dart';
import '../repositories/lesson_repository.dart';

/// Остаток бесплатного лимита озвучек через ИИ — для подписи у кнопки.
class GetTtsQuota {
  const GetTtsQuota(this._repository);

  final LessonRepository _repository;

  Future<TtsQuota> call() => _repository.ttsQuota();
}
