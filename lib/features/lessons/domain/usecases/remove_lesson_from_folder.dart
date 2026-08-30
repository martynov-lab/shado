import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

/// Убирает урок из папки — сам урок остаётся в каталоге.
class RemoveLessonFromFolder {
  const RemoveLessonFromFolder(this._repository);

  final FolderRepository _repository;

  Future<Folder> call({
    required String folderId,
    required String lessonId,
  }) => _repository.removeLesson(folderId, lessonId);
}
