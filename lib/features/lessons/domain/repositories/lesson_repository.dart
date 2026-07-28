import '../entities/audio_trim.dart';
import '../entities/lesson.dart';

/// Единственная точка доступа к урокам, которую знает presentation.
///
/// Сейчас за интерфейсом стоит только локальный источник; позже внутри `data`
/// появится удалённый источник и синхронизация — домен и UI не изменятся.
abstract interface class LessonRepository {
  Future<List<Lesson>> getLessons();

  Future<Lesson?> getLesson(String id);

  /// Импортирует аудио, определяет длительность и создаёт урок.
  ///
  /// [boundaries] — размеченные на экране создания границы (`N + 1` значение);
  /// без них куски раскладываются равномерно. [trim] — оставленный обрезкой
  /// отрезок файла; без него урок занимает файл целиком.
  Future<Lesson> createLesson({
    required String title,
    required String sourceAudioPath,
    required List<String> segmentTexts,
    List<int>? boundaries,
    AudioTrim? trim,
  });

  /// Длительность аудиофайла, ещё не привязанного к уроку: нужна, чтобы
  /// показать волну и разметку до создания урока.
  Future<int> resolveAudioDurationMs(String audioPath);

  Future<void> updateLesson(Lesson lesson);

  Future<void> deleteLesson(String id);
}
