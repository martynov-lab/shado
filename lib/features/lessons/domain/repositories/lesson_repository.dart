import 'dart:async';

import '../entities/audio_upload.dart';
import '../entities/lesson.dart';
import '../entities/lesson_category.dart';
import '../entities/tts_quota.dart';
import '../entities/tts_voice.dart';

/// Lesson access: the server is the source of truth with a cache on top.
abstract interface class LessonRepository {
  /// Lesson list from the cache.
  Future<List<Lesson>> getLessons();

  /// Fetches changes since last time and applies them to the cache; the
  /// delta watermark is kept per [language].
  Future<void> syncLessons({String language});

  /// The whole lesson with its audio already downloaded.
  Future<Lesson?> getLesson(String id);

  /// Uploads a file; [onProgress] tracks it and [cancel] aborts it.
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  });

  /// Synthesizes [text] with AI and stores the result in the audio cache;
  /// [voice] and [accent] are codes from the directories.
  Future<AudioUpload> synthesizeTts({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  });

  /// Voices the provider offers for the studied language.
  Future<TtsVoices> ttsVoices();

  /// Sample of [voice] for listening; the file lands outside the lesson
  /// audio cache.
  Future<TtsPreview> previewTtsVoice({required String voice, String? accent});

  /// Remaining free voice-overs for today.
  Future<TtsQuota> ttsQuota();

  /// Topic directory from the server.
  Future<List<Topic>> getTopics();

  /// Creates a lesson from already uploaded audio; a `null` [isPublic] lets
  /// the server decide.
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    required String? accent,
    required LessonLevel level,
    String? topicId,
    List<int>? boundaries,
    bool? isPublic,
  });

  /// Updates a lesson; a `null` [isPublic] leaves visibility untouched.
  Future<void> updateLesson(Lesson lesson, {bool? isPublic});

  Future<void> deleteLesson(String id);

  /// Wipes the lesson cache and the downloaded audio.
  Future<void> clearCache();
}
