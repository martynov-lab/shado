import '../entities/tts_quota.dart';
import '../repositories/lesson_repository.dart';

/// Remaining free AI voice-over quota, shown next to the button.
class GetTtsQuota {
  const GetTtsQuota(this._repository);

  final LessonRepository _repository;

  Future<TtsQuota> call() => _repository.ttsQuota();
}
