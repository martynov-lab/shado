import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/lesson_kind.dart';
import 'package:shado/features/lessons/domain/entities/phrase.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/entities/tts_voice.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';

/// Lessons without a server or a database; remembers whether the cache was
/// wiped, what was voiced and which phrase sets were saved.
class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository({this.lessons = const []});

  final List<Lesson> lessons;
  bool cleared = false;

  /// Text batches sent for a voice-over.
  final List<List<String>> synthesized = [];

  /// Thrown instead of voicing a batch.
  Object? synthesisError;

  /// Phrase sets saved by create or update, in order.
  final List<Lesson> savedSets = [];

  @override
  Future<void> clearCache() async => cleared = true;

  @override
  Future<List<Lesson>> getLessons() async => lessons;

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> syncLessons({String language = ''}) async {}

  @override
  Future<Set<String>> downloadedLessonIds() async => const {};

  @override
  Future<void> downloadLesson(
    String id, {
    void Function(int received, int total)? onProgress,
  }) => Future.value();

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> removeDownload(String id) async {}

  @override
  Future<Lesson?> getLesson(String id) async =>
      lessons.where((lesson) => lesson.id == id).firstOrNull;

  @override
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<AudioUpload> synthesizeTts({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<TtsVoices> ttsVoices() async => const TtsVoices();

  @override
  Future<TtsPreview> previewTtsVoice({
    required String voice,
    String? accent,
  }) async => const TtsPreview(localPath: '');

  @override
  Future<TtsQuota> ttsQuota() async => throw UnimplementedError();

  @override
  Future<List<Topic>> getTopics() async => const [];

  @override
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
  }) async => throw UnimplementedError();

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> updateLesson(Lesson lesson, {bool? isPublic}) async {}

  @override
  Future<List<AudioUpload>> synthesizePhrases({
    required List<String> texts,
    String? voice,
    String? accent,
    Object? cancel,
  }) async {
    final error = synthesisError;
    if (error != null) throw error;
    synthesized.add(texts);
    final offset = synthesized.expand((batch) => batch).length - texts.length;
    return [
      for (var i = 0; i < texts.length; i++)
        AudioUpload(
          audioId: 'tts-${offset + i}',
          durationMs: 1000,
          sizeBytes: 1,
          localPath: '/cache/tts-${offset + i}.wav',
        ),
    ];
  }

  @override
  Future<Lesson> createPhraseSet({
    required String title,
    required List<Phrase> phrases,
    required LessonLevel level,
    String? accent,
    String? topicId,
    bool? isPublic,
  }) async {
    final lesson = Lesson(
      id: 'set-${savedSets.length + 1}',
      title: title,
      audioPath: '',
      durationMs: 0,
      createdAt: DateTime.utc(2026, 11, 2),
      segments: const [],
      kind: LessonKind.expressions,
      phrases: phrases,
      isPublic: isPublic ?? false,
      accent: accent,
      level: level,
    );
    savedSets.add(lesson);
    return lesson;
  }

  @override
  Future<Lesson> updatePhraseSet(Lesson lesson, {bool? isPublic}) async {
    savedSets.add(lesson);
    return lesson;
  }

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> deleteLesson(String id) async {}
}
