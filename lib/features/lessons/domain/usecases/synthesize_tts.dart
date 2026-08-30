import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/audio_upload.dart';
import '../repositories/lesson_repository.dart';

/// Озвучка текста урока через ИИ — альтернатива загрузке аудиофайла.
///
/// Результат обрабатывается так же, как загрузка: аудио оказывается в кеше, и
/// дальше идёт обычное создание урока по `audio_id`.
class SynthesizeTts {
  const SynthesizeTts(this._repository);

  final LessonRepository _repository;

  Future<AudioUpload> call({required String text, Object? cancel}) {
    final prepared = prepareText(text);
    if (prepared.isEmpty) {
      throw const ValidationFailure('Введите текст, чтобы озвучить его');
    }
    // Длину проверяем до отправки: сервер отвергнет более длинный `422`, а
    // бесплатный лимит озвучки тратить на заведомо неудачный запрос незачем.
    if (prepared.length > kMaxTtsChars) {
      throw ValidationFailure(
        'Текст длиннее $kMaxTtsChars символов — сократите его',
      );
    }
    return _repository.synthesizeTts(text: prepared, cancel: cancel);
  }

  /// Готовит текст к отправке: убирает разделители сегментов и схлопывает
  /// пробелы. На озвучку уходит чистая фраза, а не разметка кусков.
  static String prepareText(String raw) => raw
      .replaceAll(kSegmentDelimiter, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
