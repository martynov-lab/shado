import '../models/lesson_model.dart';

/// Локальный кеш уроков. Конкретная БД — деталь реализации и наружу
/// не протекает.
///
/// С появлением сервера это именно кеш для чтения: источник истины — сервер,
/// здесь лежит последнее, что от него приходило, плюс пути к скачанному аудио.
abstract interface class LessonLocalDataSource {
  Future<List<LessonModel>> getLessons();

  Future<LessonModel?> getLesson(String id);

  /// Вставляет урок или полностью заменяет существующий с тем же id.
  Future<void> upsertLesson(LessonModel lesson);

  /// Применяет пачку уроков одной транзакцией — так приходит дельта.
  Future<void> upsertAll(List<LessonModel> lessons);

  Future<void> deleteLesson(String id);

  Future<void> deleteLessons(Iterable<String> ids);

  /// `audio_id`, на которые ссылается хоть один живой урок. По ним чистится
  /// кеш файлов: одно и то же аудио может быть у нескольких уроков сразу.
  Future<Set<String>> usedAudioIds();

  /// Верхняя граница уже полученной дельты — максимальный `updated_at` из
  /// применённых записей. `null` — синхронизации ещё не было.
  Future<String?> readSyncWatermark();

  Future<void> writeSyncWatermark(String updatedAt);

  /// Стирает кеш целиком: выход из аккаунта.
  Future<void> clear();
}
