import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/audio_upload.dart';
import '../repositories/lesson_repository.dart';

/// AI voice-over of the lesson text — an alternative to uploading a file.
class SynthesizeTts {
  const SynthesizeTts(this._repository);

  final LessonRepository _repository;

  Future<AudioUpload> call({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  }) {
    final prepared = prepareText(text);
    if (prepared.isEmpty) {
      throw const ValidationFailure('Enter text to voice it');
    }
    // Check the length before sending so the voice-over quota is not wasted.
    if (prepared.length > kMaxTtsChars) {
      throw ValidationFailure(
        'The text is longer than $kMaxTtsChars characters — shorten it',
      );
    }
    return _repository.synthesizeTts(
      text: prepared,
      voice: voice,
      accent: accent,
      cancel: cancel,
    );
  }

  /// Prepares text for sending: drops delimiters and collapses spaces.
  static String prepareText(String raw) => raw
      .replaceAll(kSegmentDelimiter, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
