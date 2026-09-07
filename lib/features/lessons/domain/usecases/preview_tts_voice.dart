import '../entities/tts_voice.dart';
import '../repositories/lesson_repository.dart';

/// Listening sample of a voice; the server picks the phrase itself.
class PreviewTtsVoice {
  const PreviewTtsVoice(this._repository);

  final LessonRepository _repository;

  Future<TtsPreview> call({required String voice, String? accent}) =>
      _repository.previewTtsVoice(voice: voice, accent: accent);
}
