import '../entities/audio_upload.dart';
import '../repositories/lesson_repository.dart';

/// Uploads the chosen file — the first step of creating a lesson.
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
