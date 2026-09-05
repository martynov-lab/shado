import '../entities/folder.dart';

/// Folder access; network only, there is no local cache.
abstract interface class FolderRepository {
  /// Folder list without nested lessons.
  Future<List<Folder>> getFolders();

  /// The whole folder with its lessons.
  Future<Folder> getFolder(String id);

  /// Creates a folder; a `null` [isPublic] lets the server decide.
  Future<Folder> createFolder({required String title, bool? isPublic});

  /// Updates a folder title and visibility on top of [version].
  Future<Folder> updateFolder({
    required String id,
    required String title,
    required int version,
    bool? isPublic,
  });

  Future<void> deleteFolder(String id);

  /// Adds lessons to a folder and returns the updated folder.
  Future<Folder> addLessons(String folderId, List<String> lessonIds);

  /// Removes a lesson from a folder and returns the updated folder.
  Future<Folder> removeLesson(String folderId, String lessonId);
}
