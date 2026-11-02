import '../../../../core/error/failures.dart';
import '../entities/audio_upload.dart';
import '../repositories/lesson_repository.dart';

/// Server limits of one batch voice-over.
const int kMaxSynthesisBatchTexts = 40;
const int kMaxSynthesisBatchChars = 2000;
const int kMaxPhraseChars = 300;

/// Voices phrases in as few batches as the server limits allow; every batch
/// costs one unit of the daily quota.
class SynthesizePhrases {
  const SynthesizePhrases(this._repository);

  final LessonRepository _repository;

  Future<List<AudioUpload>> call(
    List<String> texts, {
    String? voice,
    String? accent,
    Object? cancel,
  }) async {
    for (final text in texts) {
      if (text.trim().isEmpty) {
        throw const ValidationFailure('A phrase to voice is empty');
      }
      if (text.length > kMaxPhraseChars) {
        throw const ValidationFailure(
          'A phrase must be at most $kMaxPhraseChars characters',
        );
      }
    }
    final result = <AudioUpload>[];
    for (final batch in synthesisBatches(texts)) {
      result.addAll(
        await _repository.synthesizePhrases(
          texts: batch,
          voice: voice,
          accent: accent,
          cancel: cancel,
        ),
      );
    }
    return result;
  }
}

/// Splits [texts] into consecutive batches within the server limits.
List<List<String>> synthesisBatches(List<String> texts) {
  final batches = <List<String>>[];
  var current = <String>[];
  var chars = 0;
  for (final text in texts) {
    final full =
        current.length >= kMaxSynthesisBatchTexts ||
        chars + text.length > kMaxSynthesisBatchChars;
    if (current.isNotEmpty && full) {
      batches.add(current);
      current = <String>[];
      chars = 0;
    }
    current.add(text);
    chars += text.length;
  }
  if (current.isNotEmpty) batches.add(current);
  return batches;
}
