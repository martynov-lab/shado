import '../entities/lesson.dart';

/// Единственная точка доступа к урокам, которую знает presentation.
///
/// Сейчас за интерфейсом стоит только локальный источник; позже внутри `data`
/// появится удалённый источник и синхронизация — домен и UI не изменятся.
abstract interface class LessonRepository {
  Future<List<Lesson>> getLessons();

  Future<Lesson?> getLesson(String id);

  /// Импортирует аудио, определяет длительность и создаёт урок с равномерно
  /// расставленными границами кусков.
  Future<Lesson> createLesson({
    required String title,
    required String sourceAudioPath,
    required List<String> segmentTexts,
  });

  Future<void> updateLesson(Lesson lesson);

  Future<void> deleteLesson(String id);
}
