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
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';

/// Ответ сервера на урок: сегменты сервер возвращает такими, какими принял.
Map<String, dynamic> lessonJson({
  String id = 'lesson-1',
  String title = 'Урок',
  int durationMs = 10000,
  int version = 1,
  String audioId = 'audio-1',
  String? deletedAt,
  String updatedAt = '2026-07-28T10:00:00.000Z',
  String accent = 'US',
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
          {'index': 0, 'text': 'Раз', 'start_ms': 0, 'end_ms': durationMs},
        ],
  };
}

class FakeLocalDataSource implements LessonLocalDataSource {
  final Map<String, LessonModel> lessons = {};
  String? watermark;
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
  Future<String?> readSyncWatermark() async => watermark;

  @override
  Future<void> writeSyncWatermark(String updatedAt) async {
    watermark = updatedAt;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    lessons.clear();
    watermark = null;
  }
}

class FakeRemoteDataSource implements LessonRemoteDataSource {
  FakeRemoteDataSource({this.pages = const [], this.onPut});

  /// Страницы, которые отдаёт `list` по порядку.
  final List<LessonPage> pages;

  /// Чем отвечать на `PUT`; получает версию из `If-Match`.
  final LessonDto Function(int? version)? onPut;

  final List<String?> sinceCalls = [];
  final List<int?> putVersions = [];
  final List<List<SegmentModel>> putSegments = [];

  /// Категории, с которыми ушёл каждый `PUT`.
  final List<({LessonAccent? accent, LessonLevel? level, String? topicId})>
  putCategories = [];

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
    LessonAccent? accent,
    LessonLevel? level,
    String? topicId,
  }) async {
    putVersions.add(version);
    putSegments.add(segments);
    putCategories.add((accent: accent, level: level, topicId: topicId));
    final handler = onPut;
    if (handler != null) return handler(version);
    return LessonDto.fromJson(
      lessonJson(
        id: id,
        title: title,
        audioId: audioId,
        version: (version ?? 0) + 1,
        accent: (accent ?? LessonAccent.us).wire,
        level: (level ?? LessonLevel.b1).wire,
        topic: topicId == null ? null : {'id': topicId, 'name': 'Тема'},
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

/// Кеш в памяти: файл считается лежащим на месте, как только его «скачали».
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

  setUp(() {
    local = FakeLocalDataSource();
    audio = FakeAudioRemote();
    cache = FakeAudioCache();
    topics = FakeTopicRemote();
  });

  LessonRepositoryImpl build(FakeRemoteDataSource remote) =>
      LessonRepositoryImpl(
        localDataSource: local,
        remoteDataSource: remote,
        audioDataSource: audio,
        topicDataSource: topics,
        audioCache: cache,
      );

  group('загрузка аудио', () {
    test('возвращает копию в кеше: её играет экран создания', () async {
      final repository = build(FakeRemoteDataSource());

      final upload = await repository.uploadAudio(filePath: '/tmp/tone.mp3');

      // Именно путь кеша, а не выбранный файл: тот мог быть временной
      // распаковкой content-URI, которую система вправе стереть.
      expect(upload.localPath, '/cache/audio-1.mp3');
      expect(upload.audioId, 'audio-1');
      expect(upload.durationMs, 10000);
    });
  });

  group('создание', () {
    test('сегменты покрывают файл целиком, обрезка на сервер не уезжает', () async {
      final remote = FakeRemoteDataSource();
      // Урок размечен внутри обрезки 2000..8000, а сервер требует 0..10000.
      await build(remote).createLesson(
        title: 'Урок',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['Раз', 'Два'],
        accent: LessonAccent.us,
        level: LessonLevel.b1,
        boundaries: const [2000, 5000, 8000],
      );

      final segments = remote.putSegments.single;
      expect(segments.first.startMs, 0);
      expect(segments.last.endMs, 10000);
      // Внутренняя метка остаётся там, где её поставили.
      expect(segments.first.endMs, 5000);
      expect(segments.map((segment) => segment.index), [0, 1]);
    });

    test('создание идёт без If-Match: урока ещё нет', () async {
      final remote = FakeRemoteDataSource();

      await build(remote).createLesson(
        title: 'Урок',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['Раз'],
        accent: LessonAccent.us,
        level: LessonLevel.b1,
      );

      expect(remote.putVersions.single, isNull);
    });

    test('созданный урок попадает в кеш с локальным путём к аудио', () async {
      final remote = FakeRemoteDataSource();

      final lesson = await build(remote).createLesson(
        title: 'Урок',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['Раз'],
        accent: LessonAccent.us,
        level: LessonLevel.b1,
      );

      expect(lesson.audioPath, isNotEmpty);
      // Идентификатор генерит клиент, поэтому смотрим на то, что вернулось.
      expect(local.lessons[lesson.id]?.version, 1);
      expect(local.lessons[lesson.id]?.audioId, 'audio-1');
    });

    test('категории уходят на сервер и возвращаются в урок', () async {
      final remote = FakeRemoteDataSource();

      final lesson = await build(remote).createLesson(
        title: 'Урок',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['Раз'],
        accent: LessonAccent.uk,
        level: LessonLevel.c1,
        topicId: 'topic-7',
      );

      expect(remote.putCategories.single.accent, LessonAccent.uk);
      expect(remote.putCategories.single.level, LessonLevel.c1);
      expect(remote.putCategories.single.topicId, 'topic-7');
      expect(lesson.accent, LessonAccent.uk);
      expect(lesson.topic?.id, 'topic-7');
      // Категории живут и в кеше: без них правка потеряла бы их при `PUT`.
      expect(local.lessons[lesson.id]?.level, 'c1');
    });

    test('тему не выбрали — поле не уезжает вовсе', () async {
      final remote = FakeRemoteDataSource();

      await build(remote).createLesson(
        title: 'Урок',
        audioId: 'audio-1',
        durationMs: 10000,
        segmentTexts: const ['Раз'],
        accent: LessonAccent.us,
        level: LessonLevel.a2,
      );

      // Сервер сам поставит тему по умолчанию; прислать `null` значило бы
      // попросить его стереть тему.
      expect(remote.putCategories.single.topicId, isNull);
    });
  });

  group('правка', () {
    /// Урок в кеше, поверх которого идёт правка.
    void seedCache({int version = 3}) {
      local.lessons['lesson-1'] = LessonModel.fromDto(
        LessonDto.fromJson(lessonJson(version: version)),
        audioPath: '/cache/audio-1.mp3',
      );
      cache.files.add('audio-1');
    }

    Lesson lessonToSave() => Lesson(
      id: 'lesson-1',
      title: 'Новое название',
      audioPath: '/cache/audio-1.mp3',
      audioId: 'audio-1',
      durationMs: 10000,
      createdAt: DateTime.utc(2026, 7, 28, 9),
      segments: const [
        Segment(index: 0, text: 'Раз', startMs: 0, endMs: 10000),
      ],
    );

    test('правка уходит с версией из кеша', () async {
      seedCache();
      final remote = FakeRemoteDataSource();

      await build(remote).updateLesson(lessonToSave());

      expect(remote.putVersions.single, 3);
    });

    test('правка пересылает категории из кеша: PUT заменяет урок целиком',
        () async {
      seedCache();
      final remote = FakeRemoteDataSource();

      // Экран правки категории не трогает, поэтому в урок они не попали, —
      // но не отправить их значило бы попросить сервер их потерять.
      await build(remote).updateLesson(lessonToSave());

      expect(remote.putCategories.single.accent, LessonAccent.us);
      expect(remote.putCategories.single.level, LessonLevel.b1);
      expect(remote.putCategories.single.topicId, 'topic-1');
    });

    test('конфликт версий кладёт в кеш свежий урок и не молчит', () async {
      seedCache();
      final remote = FakeRemoteDataSource(
        onPut: (version) => throw ApiException(
          code: ApiErrorCode.versionConflict,
          message: 'version conflict',
          status: 409,
          details: {
            'code': 'version_conflict',
            'message': 'version conflict',
            'current': lessonJson(version: 4, title: 'С другого устройства'),
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

      // Молча перезаписывать чужую версию нельзя, но переписать правку поверх
      // свежей пользователь должен с актуальными данными.
      final cached = local.lessons['lesson-1']!;
      expect(cached.version, 4);
      expect(cached.title, 'С другого устройства');
      expect(cached.audioPath, '/cache/audio-1.mp3');
    });
  });

  group('синхронизация', () {
    test('первый запуск идёт без since', () async {
      final remote = FakeRemoteDataSource(
        pages: [
          LessonPage(items: [LessonDto.fromJson(lessonJson())]),
        ],
      );

      await build(remote).syncLessons();

      expect(remote.sinceCalls.single, isNull);
      expect(local.lessons, hasLength(1));
    });

    test('метка — максимальный updated_at из полученного', () async {
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

      await build(remote).syncLessons();

      expect(local.watermark, '2026-07-28T12:00:00.000Z');
    });

    test('удалённый на другом устройстве урок уходит из кеша', () async {
      local.lessons['a'] = LessonModel.fromDto(
        LessonDto.fromJson(lessonJson(id: 'a')),
        audioPath: '/cache/audio-1.mp3',
      );
      local.watermark = '2026-07-28T09:00:00.000Z';
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
      // Осиротевшее аудио уходит следом.
      expect(cache.files, isEmpty);
    });

    test('аудио, нужное другому уроку, при чистке остаётся', () async {
      // Сервер дедуплицирует загрузки по sha256, поэтому один и тот же файл
      // может быть у нескольких уроков.
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

    test('страницы обходятся по курсору', () async {
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

  group('открытие урока', () {
    test('аудио докачивается один раз, потом берётся из кеша', () async {
      final remote = FakeRemoteDataSource();
      final repository = build(remote);

      await repository.getLesson('lesson-1');
      await repository.getLesson('lesson-1');

      expect(audio.downloads, 1);
    });
  });

  test('выход стирает кеш уроков и аудио', () async {
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
