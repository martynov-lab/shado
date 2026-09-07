import '../entities/tts_voice.dart';
import '../repositories/lesson_repository.dart';

/// Voice directory for the voice-over sheet.
class GetTtsVoices {
  const GetTtsVoices(this._repository);

  final LessonRepository _repository;

  Future<TtsVoices> call() => _repository.ttsVoices();
}
