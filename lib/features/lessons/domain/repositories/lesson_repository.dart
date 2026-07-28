import 'dart:async';

import '../entities/audio_upload.dart';
import '../entities/lesson.dart';

/// Единственная точка доступа к урокам, которую знает presentation.
///
/// За интерфейсом — сервер как источник истины и локальный кеш поверх него.
/// Для домена и UI ничего не изменилось: `Lesson.audioPath` по-прежнему путь к
/// готовому к воспроизведению файлу, только теперь репозиторий при
/// необходимости его докачивает.
abstract interface class LessonRepository {
  /// Список из кеша — то, что известно после последней синхронизации.
  Future<List<Lesson>> getLessons();

  /// Тянет с сервера изменения с прошлого раза и применяет их к кешу:
  /// новые и правленые уроки обновляются, удалённые на другом устройстве
  /// исчезают вместе с осиротевшим аудио.
  Future<void> syncLessons();

  /// Урок целиком, с гарантией, что аудио лежит локально и его можно играть.
  Future<Lesson?> getLesson(String id);

  /// Отправляет выбранный файл на сервер. Длительность и пики считает он же.
  ///
  /// [onProgress] показывает ход загрузки, [cancel] её прерывает.
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  });

  /// Создаёт урок из уже загруженного аудио.
  ///
  /// [boundaries] — размеченные на волне границы (`N + 1` значение); без них
  /// куски раскладываются равномерно.
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    List<int>? boundaries,
  });

  Future<void> updateLesson(Lesson lesson);

  Future<void> deleteLesson(String id);

  /// Стирает кеш уроков и скачанное аудио: выход из аккаунта.
  Future<void> clearCache();
}
