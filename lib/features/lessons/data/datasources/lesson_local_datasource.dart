import '../models/lesson_model.dart';

/// Локальное хранилище уроков. Конкретная БД — деталь реализации и наружу
/// не протекает.
abstract interface class LessonLocalDataSource {
  Future<List<LessonModel>> getLessons();

  Future<LessonModel?> getLesson(String id);

  /// Вставляет урок или полностью заменяет существующий с тем же id.
  Future<void> upsertLesson(LessonModel lesson);

  Future<void> deleteLesson(String id);
}
