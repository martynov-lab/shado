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

  /// Upper bound of the fetched delta; `null` when never synced.
  Future<String?> readSyncWatermark();

  Future<void> writeSyncWatermark(String updatedAt);

  /// Wipes the whole cache.
  Future<void> clear();
}
