import 'dart:async';

import '../entities/audio_upload.dart';
import '../entities/lesson.dart';
import '../entities/lesson_category.dart';

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

  /// Озвучивает [text] через ИИ и возвращает результат так же, как загрузка
  /// файла: аудио уже лежит в кеше, дальше — обычное создание урока по
  /// `audio_id`. [cancel] прерывает синтез.
  Future<AudioUpload> synthesizeTts({required String text, Object? cancel});

  /// Справочник тем с сервера. Спрашивается при входе на экран создания:
  /// тему могли переименовать или удалить.
  Future<List<Topic>> getTopics();

  /// Создаёт урок из уже загруженного аудио.
  ///
  /// [boundaries] — размеченные на волне границы (`N + 1` значение); без них
  /// куски раскладываются равномерно. [topicId] можно не задавать — тогда
  /// сервер поставит уроку тему по умолчанию. [isPublic] задаёт публичность,
  /// когда ей управляет автор (owner); `null` — решает сервер.
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    required LessonAccent accent,
    required LessonLevel level,
    String? topicId,
    List<int>? boundaries,
    bool? isPublic,
  });

  /// Правит урок. [isPublic] шлём только когда публичностью управляет автор
  /// (owner); `null` — сервер оставляет её как есть.
  Future<void> updateLesson(Lesson lesson, {bool? isPublic});

  Future<void> deleteLesson(String id);

  /// Стирает кеш уроков и скачанное аудио: выход из аккаунта.
  Future<void> clearCache();
}
