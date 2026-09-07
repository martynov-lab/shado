import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/lessons/data/datasources/audio_cache.dart';
import 'package:shado/features/lessons/data/datasources/audio_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:shado/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:shado/features/lessons/data/models/audio_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';
import 'package:shado/features/lessons/data/models/segment_model.dart';
import 'package:shado/features/lessons/data/models/waveform_peaks.dart';
import 'package:shado/features/lessons/data/repositories/lesson_repository_impl.dart';
import 'package:shado/features/lessons/data/datasources/topic_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/tts_remote_datasource.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/entities/tts_voice.dart';

/// The server response for a lesson; segments come back as they were sent.
Map<String, dynamic> lessonJson({
  String id = 'lesson-1',
  String title = 'Lesson',
  int durationMs = 10000,
  int version = 1,
  String audioId = 'audio-1',
  String? deletedAt,
  String updatedAt = '2026-07-28T10:00:00.000Z',
  String language = 'en',
  String? accent = 'US',
  String level = 'b1',
  Map<String, dynamic>? topic = const {'id': 'topic-1', 'name': 'Education'},
  List<Map<String, dynamic>>? segments,
}) {
  return {
    'id': id,
    'title': title,
    'duration_ms': durationMs,
    'created_at': '2026-07-28T09:00:00.000Z',
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
    'version': version,
    'language': language,
    'accent': accent,
    'level': level,
    'topic': topic,
    'audio': {
      'id': audioId,
      'url': 'http://localhost/v1/audio/$audioId/file',
      'content_type': 'audio/mpeg',
      'size_bytes': 1000,
      'sha256': 'abc',
      'duration_ms': durationMs,
    },
    'segments':
        segments ??
        [
          {'index': 0, 'text': 'One', 'start_ms': 0, 'end_ms': durationMs},
        ],
  };
}

class FakeLocalDataSource implements LessonLocalDataSource {
  final Map<String, LessonModel> lessons = {};

  /// Delta watermark per language code.
  final Map<String, String> watermarks = {};

  bool cleared = false;

  @override
  Future<List<LessonModel>> getLessons() async => lessons.values.toList();

  @override
  Future<LessonModel?> getLesson(String id) async => lessons[id];

  @override
  Future<void> upsertLesson(LessonModel lesson) async {
    lessons[lesson.id] = lesson;
  }

  @override
  Future<void> upsertAll(List<LessonModel> models) async {
    for (final model in models) {
      lessons[model.id] = model;
    }
  }

  @override
  Future<void> deleteLesson(String id) async {
    lessons.remove(id);
  }

  @override
  Future<void> deleteLessons(Iterable<String> ids) async {
    for (final id in ids) {
      lessons.remove(id);
    }
  }

  @override
  Future<Set<String>> usedAudioIds() async =>
      lessons.values.map((lesson) => lesson.audioId).toSet();

  @override
  Future<String?> readSyncWatermark(String language) async =>
      watermarks[language];

  @override
  Future<void> writeSyncWatermark(String language, String updatedAt) async {
    watermarks[language] = updatedAt;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    lessons.clear();
    watermarks.clear();
  }
}

class FakeRemoteDataSource implements LessonRemoteDataSource {
  FakeRemoteDataSource({this.pages = const [], this.onPut});

  /// Pages returned by `list` in order.
  final List<LessonPage> pages;

  /// What to answer a `PUT` with; it gets the version from `If-Match`.
  final LessonDto Function(int? version)? onPut;

  final List<String?> sinceCalls = [];
  final List<int?> putVersions = [];
  final List<List<SegmentModel>> putSegments = [];

  /// Categories sent with each `PUT`.
  final List<({String? accent, LessonLevel? level, String? topicId})>
  putCategories = [];

  /// The `is_public` sent with each `PUT`; `null` means it was omitted.
  final List<bool?> putIsPublic = [];

  final List<String> deleted = [];
  int _page = 0;

  @override
  Future<LessonPage> list({String? since, int? limit, String? cursor}) async {
    sinceCalls.add(since);
    if (_page >= pages.length) return const LessonPage(items: []);
    return pages[_page++];
  }

  @override
  Future<LessonDto> getLesson(String id) async =>
      LessonDto.fromJson(lessonJson(id: id));

  @override
  Future<LessonDto> putLesson({
    required String id,
    required String title,
    required String audioId,
    required DateTime createdAt,
    required List<SegmentModel> segments,
    int? version,
    String? accent,
    LessonLevel? level,
    String? topicId,
    bool? isPublic,
  }) async {
    putVersions.add(version);
    putSegments.add(segments);
    putCategories.add((accent: accent, level: level, topicId: topicId));
    putIsPublic.add(isPublic);
    final handler = onPut;
    if (handler != null) return handler(version);
    return LessonDto.fromJson(
      lessonJson(
        id: id,
        title: title,
        audioId: audioId,
        version: (version ?? 0) + 1,
        accent: accent ?? 'US',
        level: (level ?? LessonLevel.b1).wire,
        topic: topicId == null ? null : {'id': topicId, 'name': 'Topic'},
        segments: [for (final segment in segments) segment.toJson()],
      ),
    );
  }

  @override
  Future<void> deleteLesson(String id) async => deleted.add(id);
}

class FakeTopicRemote implements TopicRemoteDataSource {
  FakeTopicRemote([this.topics = const []]);

  final List<Topic> topics;
  int calls = 0;

  @override
  Future<List<Topic>> list() async {
    calls++;
    return topics;
  }

  @override
  Future<Topic> create(String name) => throw UnimplementedError();

  @override
  Future<Topic> rename({required String id, required String name}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();
}

class FakeAudioRemote implements AudioRemoteDataSource {
  int downloads = 0;

  @override
  Future<AudioDto> upload({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancelToken,
  }) async {
    onProgress?.call(100, 100);
    return AudioDto.fromJson({
      'id': 'audio-1',
      'content_type': 'audio/mpeg',
      'size_bytes': 100,
      'sha256': 'abc',
      'duration_ms': 10000,
    });
  }

  @override
  Future<WaveformPeaks> peaks(String audioId, {int resolution = 2000}) async =>
      const WaveformPeaks(minima: [], maxima: []);

  @override
  Future<void> download({
    required String audioId,
    required String targetPath,
    void Function(int received, int total)? onProgress,
    Object? cancelToken,
  }) async {
    downloads++;
  }
}

/// Voice-over returning a ready [AudioDto] as if the text was synthesized.
class FakeTtsRemote implements TtsRemoteDataSource {
  final List<String> synthesized = [];

  /// Voice and accent of each synthesis request.
  final List<({String? voice, String? accent})> synthesisOptions = [];

  final List<({String voice, String? accent})> previews = [];

  @override
  Future<AudioDto> synthesize({
    required String text,
    String? voice,
    String? accent,
    CancelToken? cancelToken,
  }) async {
    synthesized.add(text);
    synthesisOptions.add((voice: voice, accent: accent));
    return AudioDto.fromJson({
      'id': 'tts-1',
      'content_type': 'audio/wav',
      'size_bytes': 200,
      'sha256': 'def',
      'duration_ms': 4200,
    });
  }

  @override
  Future<TtsVoices> voices() async => const TtsVoices(
    items: [TtsVoice(name: 'Kore', description: 'Soft')],
    defaultVoice: 'Kore',
  );

  @override
  Future<TtsPreviewResponse> preview({
    required String voice,
    String? accent,
  }) async {
    previews.add((voice: voice, accent: accent));
    return (
      audio: AudioDto.fromJson({
        'id': 'tts-sample-1',
        'content_type': 'audio/wav',
        'size_bytes': 100,
        'sha256': '',
        'duration_ms': 1500,
      }),
      text: 'Sample phrase',
      cached: false,
    );
  }

  @override
  Future<TtsQuota> quota() async =>
      const TtsQuota(provider: 'gemini', day: _window, minute: _window);
}

const _window = TtsQuotaWindow(used: 0, limit: 14, remaining: 14);

/// In-memory cache: a file counts as present once it was downloaded.
class FakeAudioCache implements AudioCache {
  final Set<String> files = {};
  final List<Set<String>> retained = [];
  bool cleared = false;

  @override
  Future<String?> find(String audioId) async =>
      files.contains(audioId) ? '/cache/$audioId.mp3' : null;

  @override
  Future<String> pathFor(String audioId, String extension) async {
    files.add(audioId);
    return '/cache/$audioId.$extension';
  }

  @override
  Future<String> put({
    required String audioId,
    required String extension,
    required String sourcePath,
  }) async {
    files.add(audioId);
    return '/cache/$audioId.$extension';
  }

  @override
  Future<bool> verify(String path, String sha256) async => true;

  @override
  Future<void> remove(String audioId) async => files.remove(audioId);

  @override
  Future<void> retainOnly(Set<String> audioIds) async {
    retained.add(audioIds);
    files.retainWhere(audioIds.contains);
  }

  @override
  Future<void> trimToSize(int maxBytes) async {}

  @override
  Future<void> clear() async {
    cleared = true;
    files.clear();
  }
}

void main() {
  late FakeLocalDataSource local;
  late FakeAudioRemote audio;
  late FakeAudioCache cache;
  late FakeTopicRemote topics;
  late FakeTtsRemote tts;

  setUp(() {
    local = FakeLocalDataSource();
    audio = FakeAudioRemote();
    cache = FakeAudioCache();
    topics = FakeTopicRemote();
    tts = FakeTtsRemote();
  });

  LessonRepositoryImpl build(FakeRemoteDataSource remote) =>
      LessonRepositoryImpl(
        localDataSource: local,
        remoteDataSource: remote,
        audioDataSource: audio,
        topicDataSource: topics,
        ttsDataSource: tts,
        audioCache: cache,
      );

  group('audio upload', () {
    test('returns the cached copy: the creation screen plays it', () async {
      final repository = build(FakeRemoteDataSource());

      final upload = await repository.uploadAudio(filePath: '/tmp/tone.mp3');

      // The cache path, not the source file.
      expect(upload.localPath, '/cache/audio-1.mp3');
      expect(upload.audioId, 'audio-1');
      expect(upload.durationMs, 10000);
    });
  });

  group('AI voice-over', () {
    test('downloads the synthesis into the cache and returns a local path, like an upload', () async {
      final repository = build(FakeRemoteDataSource());

      final upload = await repository.synthesizeTts(text: 'Hello there');

      expect(tts.synthesized.single, 'Hello there');
      // The synthesized file is fetched once and cached under its audio_id.
      expect(audio.downloads, 1);
      expect(upload.audioId, 'tts-1');
      expect(upload.durationMs, 4200);
      // Gemini TTS returns wav, so the file lands in the cache as .wav.
      expect(upload.localPath, '/cache/tts-1.wav');
    });

    test('the chosen voice and accent go into the synthesis request', () async {
      final repository = build(FakeRemoteDataSource());

      await repository.synthesizeTts(
        text: 'Hello there',
        voice: 'Kore',
        accent: 'AU',
      );

      expect(tts.synthesisOptions.single.voice, 'Kore');
      expect(tts.synthesisOptions.single.accent, 'AU');
    });

    test('with no voice chosen the fields are omitted and the server picks its own', () async {
      final repository = build(FakeRemoteDataSource());

      await repository.synthesizeTts(text: 'Hello there');

      expect(tts.synthesisOptions.single.voice, isNull);
      expect(tts.synthesisOptions.single.accent, isNull);
    });
  });

  group('creation', () {
    test('segments cover the whole file and the trim never reaches the server', () async {
      final remote = FakeRemoteDataSource();
      // The lesson is marked inside the trim, but the server wants 0..10000.
      await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One', 'Two'],
        accent: 'US',
        level: LessonLevel.b1,
        boundaries: const [2000, 5000, 8000],
      );

      final segments = remote.putSegments.single;
      expect(segments.first.startMs, 0);
      expect(segments.last.endMs, 10000);
      // An inner marker stays where it was placed.
      expect(segments.first.endMs, 5000);
      expect(segments.map((segment) => segment.index), [0, 1]);
    });

    test('creation goes without If-Match: the lesson does not exist yet', () async {
      final remote = FakeRemoteDataSource();

      await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One'],
        accent: 'US',
        level: LessonLevel.b1,
      );

      expect(remote.putVersions.single, isNull);
    });

    test('is_public is not sent when the visibility was not set', () async {
      final remote = FakeRemoteDataSource();

      await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One'],
        accent: 'US',
        level: LessonLevel.b1,
      );

      expect(remote.putIsPublic.single, isNull);
    });

    test('an explicit visibility goes to the server', () async {
      final remote = FakeRemoteDataSource();

      await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One'],
        accent: 'US',
        level: LessonLevel.b1,
        isPublic: false,
      );

      expect(remote.putIsPublic.single, isFalse);
    });

    test('the created lesson lands in the cache with a local audio path', () async {
      final remote = FakeRemoteDataSource();

      final lesson = await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One'],
        accent: 'US',
        level: LessonLevel.b1,
      );

      expect(lesson.audioPath, isNotEmpty);
      // The client generates the id, so we look at what came back.
      expect(local.lessons[lesson.id]?.version, 1);
      expect(local.lessons[lesson.id]?.audioId, 'audio-1');
    });

    test('categories go to the server and come back in the lesson', () async {
      final remote = FakeRemoteDataSource();

      final lesson = await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One'],
        accent: 'UK',
        level: LessonLevel.c1,
        topicId: 'topic-7',
      );

      expect(remote.putCategories.single.accent, 'UK');
      expect(remote.putCategories.single.level, LessonLevel.c1);
      expect(remote.putCategories.single.topicId, 'topic-7');
      expect(lesson.accent, 'UK');
      expect(lesson.topic?.id, 'topic-7');
      // Categories live in the cache: a `PUT` without them would drop them.
      expect(local.lessons[lesson.id]?.level, 'c1');
    });

    test('with no topic chosen the field is not sent at all', () async {
      final remote = FakeRemoteDataSource();

      await build(remote).createLesson(
        title: 'Lesson',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['One'],
        accent: 'US',
        level: LessonLevel.a2,
      );

      // With no topic the key is not sent and the server picks its own.
      expect(remote.putCategories.single.topicId, isNull);
    });
  });

  group('editing', () {
    /// The cached lesson the edit is applied on top of.
    void seedCache({int version = 3}) {
      local.lessons['lesson-1'] = LessonModel.fromDto(
        LessonDto.fromJson(lessonJson(version: version)),
        audioPath: '/cache/audio-1.mp3',
      );
      cache.files.add('audio-1');
    }

    Lesson lessonToSave() => Lesson(
      id: 'lesson-1',
      title: 'New title',
      audioPath: '/cache/audio-1.mp3',
      audioId: 'audio-1',
      durationMs: 10000,
      createdAt: DateTime.utc(2026, 7, 28, 9),
      segments: const [
        Segment(index: 0, text: 'One', startMs: 0, endMs: 10000),
      ],
    );

    test('an edit goes with the version from the cache', () async {
      seedCache();
      final remote = FakeRemoteDataSource();

      await build(remote).updateLesson(lessonToSave());

      expect(remote.putVersions.single, 3);
    });

    test('an edit resends categories from the cache: PUT replaces the whole lesson',
        () async {
      seedCache();
      final remote = FakeRemoteDataSource();

      // `PUT` replaces the whole lesson, so categories are resent as is.
      await build(remote).updateLesson(lessonToSave());

      expect(remote.putCategories.single.accent, 'US');
      expect(remote.putCategories.single.level, LessonLevel.b1);
      expect(remote.putCategories.single.topicId, 'topic-1');
    });

    test('a version conflict caches the fresh lesson and does not stay silent', () async {
      seedCache();
      final remote = FakeRemoteDataSource(
        onPut: (version) => throw ApiException(
          code: ApiErrorCode.versionConflict,
          message: 'version conflict',
          status: 409,
          details: {
            'code': 'version_conflict',
            'message': 'version conflict',
            'current': lessonJson(version: 4, title: 'From another device'),
          },
        ),
      );

      await expectLater(
        build(remote).updateLesson(lessonToSave()),
        throwsA(
          isA<ApiException>().having(
            (error) => error.isVersionConflict,
            'versionConflict',
            isTrue,
          ),
        ),
      );

      // On a conflict the fresh version must end up in the cache.
      final cached = local.lessons['lesson-1']!;
      expect(cached.version, 4);
      expect(cached.title, 'From another device');
      expect(cached.audioPath, '/cache/audio-1.mp3');
    });
  });

  group('synchronization', () {
    test('the first run goes without since', () async {
      final remote = FakeRemoteDataSource(
        pages: [
          LessonPage(items: [LessonDto.fromJson(lessonJson())]),
        ],
      );

      await build(remote).syncLessons();

      expect(remote.sinceCalls.single, isNull);
      expect(local.lessons, hasLength(1));
    });

    test('the watermark is the maximum updated_at received', () async {
      final remote = FakeRemoteDataSource(
        pages: [
          LessonPage(
            items: [
              LessonDto.fromJson(
                lessonJson(id: 'a', updatedAt: '2026-07-28T10:00:00.000Z'),
              ),
              LessonDto.fromJson(
                lessonJson(id: 'b', updatedAt: '2026-07-28T12:00:00.000Z'),
              ),
            ],
          ),
        ],
      );

      await build(remote).syncLessons(language: 'en');

      // The watermark hangs on the language, not on the catalog as a whole.
      expect(local.watermarks['en'], '2026-07-28T12:00:00.000Z');
    });

    test('a watermark of another language does not disturb the first sync', () async {
      local.watermarks['en'] = '2026-07-28T12:00:00.000Z';
      final remote = FakeRemoteDataSource(
        pages: [
          LessonPage(items: [LessonDto.fromJson(lessonJson(id: 'a'))]),
        ],
      );

      await build(remote).syncLessons(language: 'fr');

      // A fresh language starts without `since` — the whole catalog arrives.
      expect(remote.sinceCalls.single, isNull);
    });

    test('a lesson deleted on another device leaves the cache', () async {
      local.lessons['a'] = LessonModel.fromDto(
        LessonDto.fromJson(lessonJson(id: 'a')),
        audioPath: '/cache/audio-1.mp3',
      );
      local.watermarks[''] = '2026-07-28T09:00:00.000Z';
      cache.files.add('audio-1');

      final remote = FakeRemoteDataSource(
        pages: [
          LessonPage(
            items: [
              LessonDto.fromJson(
                lessonJson(id: 'a', deletedAt: '2026-07-28T13:00:00.000Z'),
              ),
            ],
          ),
        ],
      );

      await build(remote).syncLessons();

      expect(local.lessons, isEmpty);
      expect(remote.sinceCalls.single, '2026-07-28T09:00:00.000Z');
      // Orphaned audio is removed right after.
      expect(cache.files, isEmpty);
    });

    test('audio needed by another lesson survives the cleanup', () async {
      // One `audio_id` may belong to several lessons.
      for (final id in ['a', 'b']) {
        local.lessons[id] = LessonModel.fromDto(
          LessonDto.fromJson(lessonJson(id: id)),
          audioPath: '/cache/audio-1.mp3',
        );
      }
      cache.files.add('audio-1');

      await build(FakeRemoteDataSource()).deleteLesson('a');

      expect(local.lessons.keys, ['b']);
      expect(cache.files, contains('audio-1'));
    });

    test('pages are walked by cursor', () async {
      final remote = FakeRemoteDataSource(
        pages: [
          LessonPage(
            items: [LessonDto.fromJson(lessonJson(id: 'a'))],
            nextCursor: 'cursor-1',
          ),
          LessonPage(items: [LessonDto.fromJson(lessonJson(id: 'b'))]),
        ],
      );

      await build(remote).syncLessons();

      expect(local.lessons.keys, containsAll(['a', 'b']));
      expect(remote.sinceCalls, hasLength(2));
    });
  });

  group('opening a lesson', () {
    test('audio is downloaded once and then taken from the cache', () async {
      final remote = FakeRemoteDataSource();
      final repository = build(remote);

      await repository.getLesson('lesson-1');
      await repository.getLesson('lesson-1');

      expect(audio.downloads, 1);
    });
  });

  test('signing out wipes the lesson and audio caches', () async {
    local.lessons['a'] = LessonModel.fromDto(
      LessonDto.fromJson(lessonJson(id: 'a')),
      audioPath: '/cache/audio-1.mp3',
    );
    cache.files.add('audio-1');

    await build(FakeRemoteDataSource()).clearCache();

    expect(local.cleared, isTrue);
    expect(cache.cleared, isTrue);
  });
}
