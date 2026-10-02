import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/entities/tts_voice.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';

/// Lessons without a server or a database; remembers whether the cache was
/// wiped.
class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository({this.lessons = const []});

  final List<Lesson> lessons;
  bool cleared = false;

  @override
  Future<void> clearCache() async => cleared = true;

  @override
  Future<List<Lesson>> getLessons() async => lessons;

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> syncLessons({String language = ''}) async {}

  @override
  Future<Lesson?> getLesson(String id) async => null;

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
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> deleteLesson(String id) async {}
}
