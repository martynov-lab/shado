import '../entities/folder.dart';

/// Доступ к папкам (§6.2). Сервер — источник истины; папки тянутся по сети,
/// а не кешируются локально, как уроки: это лёгкая группировка поверх каталога.
abstract interface class FolderRepository {
  /// Список папок (публичные + свои приватные), без вложенных уроков.
  Future<List<Folder>> getFolders();

  /// Папка целиком, с её уроками.
  Future<Folder> getFolder(String id);

  /// Создаёт папку. UUID генерит клиент, поэтому повтор при обрыве не создаёт
  /// дубль. [isPublic] задаёт видимость, когда ей управляет автор (owner);
  /// `null` — решает сервер по роли.
  Future<Folder> createFolder({required String title, bool? isPublic});

  /// Правит название и видимость папки поверх [version] (`If-Match`).
  Future<Folder> updateFolder({
    required String id,
    required String title,
    required int version,
    bool? isPublic,
  });

  Future<void> deleteFolder(String id);

  /// Добавляет уроки в папку и возвращает её обновлённой.
  Future<Folder> addLessons(String folderId, List<String> lessonIds);

  /// Убирает урок из папки и возвращает её обновлённой.
  Future<Folder> removeLesson(String folderId, String lessonId);
}
