import '../../domain/entities/folder.dart';
import '../models/lesson_model.dart';

/// Local read cache of lessons.
abstract interface class LessonLocalDataSource {
  Future<List<LessonModel>> getLessons();

  Future<LessonModel?> getLesson(String id);

  /// Inserts a lesson or fully replaces the one with the same id.
  Future<void> upsertLesson(LessonModel lesson);

  /// Applies a batch of lessons in one transaction, the way a delta arrives.
  Future<void> upsertAll(List<LessonModel> lessons);

  Future<void> deleteLesson(String id);

  Future<void> deleteLessons(Iterable<String> ids);

  /// The `audio_id` values referenced by at least one lesson.
  Future<Set<String>> usedAudioIds();

  /// Ids of lessons the user downloaded for offline study.
  Future<Set<String>> downloadedIds();

  Future<void> markDownloaded(String id);

  Future<void> unmarkDownloaded(String id);

  /// Library root as last fetched: its folders and unfiled lesson ids;
  /// `null` when it was never fetched.
  Future<({List<Folder> folders, List<String> lessonIds})?> readLibrary();

  Future<void> writeLibrary({
    required List<Folder> folders,
    required List<String> lessonIds,
  });

  /// Folder as last opened with the ids of its lessons; `null` when it was
  /// never opened.
  Future<({Folder folder, List<String> lessonIds})?> readFolder(String id);

  /// Saves the folder with the ids of its [Folder.lessons].
  Future<void> writeFolder(Folder folder);

  Future<void> deleteFolder(String id);

  /// Upper bound of the fetched delta for [language]; `null` when that
  /// language was never synced.
  Future<String?> readSyncWatermark(String language);

  Future<void> writeSyncWatermark(String language, String updatedAt);

  /// Wipes the whole cache.
  Future<void> clear();
}
