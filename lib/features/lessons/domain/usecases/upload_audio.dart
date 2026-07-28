import '../entities/audio_upload.dart';
import '../repositories/lesson_repository.dart';

/// Отправка выбранного файла на сервер — первый шаг создания урока.
///
/// Заменила локальный замер длительности: её, как и пики волны, теперь считает
/// сервер, поэтому результат одинаков на всех платформах.
class UploadAudio {
  const UploadAudio(this._repository);

  final LessonRepository _repository;

  Future<AudioUpload> call({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  }) {
    return _repository.uploadAudio(
      filePath: filePath,
      onProgress: onProgress,
      cancel: cancel,
    );
  }
}
