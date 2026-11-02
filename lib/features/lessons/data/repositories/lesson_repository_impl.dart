import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/audio_upload.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/phrase.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/entities/tts_quota.dart';
import '../../domain/entities/tts_voice.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/audio_cache.dart';
import '../datasources/audio_remote_datasource.dart';
import '../datasources/lesson_local_datasource.dart';
import '../datasources/lesson_remote_datasource.dart';
import '../datasources/topic_remote_datasource.dart';
import '../datasources/tts_remote_datasource.dart';
import '../models/audio_dto.dart';
import '../models/lesson_dto.dart';
import '../models/lesson_model.dart';
import '../models/phrase_model.dart';
import '../models/segment_model.dart';

/// Lessons: the server is the source of truth, sqflite is the read cache and
/// audio files are cached by `audio_id`.
class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl({
    required LessonLocalDataSource localDataSource,
    required LessonRemoteDataSource remoteDataSource,
    required AudioRemoteDataSource audioDataSource,
    required TopicRemoteDataSource topicDataSource,
    required TtsRemoteDataSource ttsDataSource,
    required AudioCache audioCache,
    Uuid uuid = const Uuid(),
  }) : _local = localDataSource,
       _remote = remoteDataSource,
       _audio = audioDataSource,
       _topics = topicDataSource,
       _tts = ttsDataSource,
       _cache = audioCache,
       _uuid = uuid;

  /// Audio cache size limit; older files are evicted beyond it.
  static const int _maxCacheBytes = 2 * 1024 * 1024 * 1024;

  /// Lesson list page size.
  static const int _pageLimit = 100;

  /// Temporary directory for voice samples.
  static const String _sampleDirName = 'tts_samples';

  final LessonLocalDataSource _local;
  final LessonRemoteDataSource _remote;
  final AudioRemoteDataSource _audio;
  final TopicRemoteDataSource _topics;
  final TtsRemoteDataSource _tts;
  final AudioCache _cache;
  final Uuid _uuid;

  @override
  Future<List<Lesson>> getLessons() async {
    final models = await _local.getLessons();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<void> syncLessons({String language = ''}) async {
    final since = await _local.readSyncWatermark(language);
    final fresh = <LessonModel>[];
    final removed = <String>[];
    var watermark = since;

    String? cursor;
    do {
      // With `since` a delta arrives that also lists deleted lessons.
      final page = await _remote.list(
        since: since,
        limit: _pageLimit,
        cursor: cursor,
      );
      for (final dto in page.items) {
        watermark = _laterOf(watermark, dto.updatedAt);
        if (dto.isDeleted) {
          removed.add(dto.id);
          continue;
        }
        fresh.add(_withCachedAudio(dto, await _local.getLesson(dto.id)));
      }
      cursor = page.nextCursor;
    } while (cursor != null);

    await _local.deleteLessons(removed);
    await _local.upsertAll(fresh);
    // The watermark is the max `updated_at` of the response, not device time.
    if (watermark != null) {
      await _local.writeSyncWatermark(language, watermark);
    }
    await _tidyAudioCache();
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    final LessonDto dto;
    try {
      dto = await _remote.getLesson(id);
    } on ApiException catch (error) {
      // The lesson is gone or not ours — drop it from the cache.
      if (error.isNotFound) {
        await _forget(id);
        return null;
      }
      rethrow;
    } on NetworkFailure {
      // Offline: return the last known lesson when its audio is downloaded.
      return _cachedPlayable(id);
    }

    return (await _store(dto)).toEntity();
  }

  @override
  Future<Set<String>> downloadedLessonIds() => _local.downloadedIds();

  @override
  Future<void> downloadLesson(
    String id, {
    void Function(int received, int total)? onProgress,
  }) async {
    await _store(await _remote.getLesson(id), onProgress: onProgress);
    await _local.markDownloaded(id);
  }

  @override
  Future<void> removeDownload(String id) async {
    await _local.unmarkDownloaded(id);
    await _tidyAudioCache();
  }

  @override
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  }) async {
    final dto = await _audio.upload(
      filePath: filePath,
      onProgress: onProgress,
      cancelToken: cancel is CancelToken ? cancel : null,
    );
    // The file is already here — put it into the cache right away.
    final cached = await _cache.put(
      audioId: dto.id,
      extension: dto.fileExtension,
      sourcePath: filePath,
    );
    return AudioUpload(
      audioId: dto.id,
      durationMs: dto.durationMs,
      sizeBytes: dto.sizeBytes,
      // Return the cached copy: the system may delete the original file.
      localPath: cached,
    );
  }

  @override
  Future<AudioUpload> synthesizeTts({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  }) async {
    final dto = await _tts.synthesize(
      text: text,
      voice: voice,
      accent: accent,
      cancelToken: cancel is CancelToken ? cancel : null,
    );
    // Synthesis returns a link only — download the file into the cache.
    final localPath = await _ensureAudioFile(dto);
    return AudioUpload(
      audioId: dto.id,
      durationMs: dto.durationMs,
      sizeBytes: dto.sizeBytes,
      localPath: localPath,
    );
  }

  @override
  Future<List<AudioUpload>> synthesizePhrases({
    required List<String> texts,
    String? voice,
    String? accent,
    Object? cancel,
  }) async {
    final items = await _tts.synthesizeBatch(
      texts: texts,
      voice: voice,
      accent: accent,
      cancelToken: cancel is CancelToken ? cancel : null,
    );
    return [
      for (final dto in items)
        AudioUpload(
          audioId: dto.id,
          durationMs: dto.durationMs,
          sizeBytes: dto.sizeBytes,
          localPath: await _ensureAudioFile(dto),
        ),
    ];
  }

  @override
  Future<TtsVoices> ttsVoices() => _tts.voices();

  @override
  Future<TtsPreview> previewTtsVoice({
    required String voice,
    String? accent,
  }) async {
    final response = await _tts.preview(voice: voice, accent: accent);
    return TtsPreview(
      localPath: await _downloadSample(response.audio),
      text: response.text,
      cached: response.cached,
    );
  }

  @override
  Future<TtsQuota> ttsQuota() => _tts.quota();

  @override
  Future<List<Topic>> getTopics() => _topics.list();

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
  }) async {
    // The client generates the UUID, so a repeated `PUT` makes no duplicate.
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc();
    final segments = _segmentsFor(
      texts: segmentTexts,
      boundaries: boundaries,
      durationMs: durationMs,
    );

    final dto = await _remote.putLesson(
      id: id,
      title: title,
      audioId: audioId,
      createdAt: createdAt,
      segments: segments,
      accent: accent,
      level: level,
      topicId: topicId,
      isPublic: isPublic,
    );
    final model = await _store(dto);
    return model.toEntity();
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
    final dto = await _remote.putPhraseSet(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now().toUtc(),
      phrases: phrases,
      level: level,
      accent: accent,
      topicId: topicId,
      isPublic: isPublic,
    );
    return (await _store(dto)).toEntity();
  }

  @override
  Future<Lesson> updatePhraseSet(Lesson lesson, {bool? isPublic}) async {
    final cached = await _local.getLesson(lesson.id);
    if (cached == null) {
      throw NotFoundFailure('Lesson ${lesson.id} not found in the cache');
    }
    try {
      final dto = await _remote.putPhraseSet(
        id: lesson.id,
        title: lesson.title,
        createdAt: lesson.createdAt,
        phrases: lesson.phrases,
        level: lesson.level ?? LessonLevel.parse(cached.level) ?? LessonLevel.b1,
        // Version from the cache: the edit applies on top of the last seen one.
        version: cached.version,
        accent: lesson.accent ?? _nullIfEmpty(cached.accent),
        topicId: lesson.topic?.id ?? _nullIfEmpty(cached.topicId),
        isPublic: isPublic,
      );
      return (await _store(dto)).toEntity();
    } on ApiException catch (error) {
      final current = error.current;
      if (!error.isVersionConflict || current == null) rethrow;
      // Version conflict: store the fresh version, let the error bubble up.
      await _local.upsertLesson(
        _withCachedAudio(LessonDto.fromJson(current), cached),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateLesson(Lesson lesson, {bool? isPublic}) async {
    final cached = await _local.getLesson(lesson.id);
    if (cached == null) {
      throw NotFoundFailure('Lesson ${lesson.id} not found in the cache');
    }
    final segments = _segmentsFor(
      texts: [for (final segment in lesson.segments) segment.text],
      boundaries: lesson.boundaries,
      durationMs: cached.durationMs,
    );

    try {
      final dto = await _remote.putLesson(
        id: lesson.id,
        title: lesson.title,
        audioId: cached.audioId,
        createdAt: lesson.createdAt,
        segments: segments,
        // Version from the cache: the edit applies on top of the last seen one.
        version: cached.version,
        // `PUT` replaces the whole lesson — categories are resent as is.
        accent: lesson.accent ?? _nullIfEmpty(cached.accent),
        level: lesson.level ?? LessonLevel.parse(cached.level),
        topicId: lesson.topic?.id ?? _nullIfEmpty(cached.topicId),
        isPublic: isPublic,
      );
      await _local.upsertLesson(
        LessonModel.fromDto(dto, audioPath: cached.audioPath),
      );
    } on ApiException catch (error) {
      final current = error.current;
      if (!error.isVersionConflict || current == null) rethrow;
      // Version conflict: store the fresh version, let the error bubble up.
      final fresh = LessonDto.fromJson(current);
      await _local.upsertLesson(
        LessonModel.fromDto(fresh, audioPath: cached.audioPath),
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteLesson(String id) async {
    try {
      await _remote.deleteLesson(id);
    } on ApiException catch (error) {
      // Deleting something that does not exist counts as success.
      if (!error.isNotFound) rethrow;
    }
    await _forget(id);
  }

  @override
  Future<void> clearCache() async {
    await _local.clear();
    await _cache.clear();
  }

  /// Segments for the server: they cover the whole `0..duration_ms` file.
  List<SegmentModel> _segmentsFor({
    required List<String> texts,
    required List<int>? boundaries,
    required int durationMs,
  }) {
    final full = AudioTrim.full(durationMs);
    final source = boundaries != null && boundaries.length == texts.length + 1
        ? boundaries
        : SegmentBoundaries.even(texts.length, full);
    final normalized = SegmentBoundaries.normalize(source, full);
    return [
      for (var i = 0; i < texts.length; i++)
        SegmentModel(
          index: i,
          text: texts[i],
          startMs: normalized[i],
          endMs: normalized[i + 1],
        ),
    ];
  }

  /// Puts the lesson with its downloaded audio into the cache.
  Future<LessonModel> _store(
    LessonDto dto, {
    void Function(int received, int total)? onProgress,
  }) async {
    final audio = dto.audio;
    final model = audio == null
        ? LessonModel.fromDto(
            dto,
            audioPath: '',
            phrases: await _ensurePhraseFiles(
              dto.phrases,
              onProgress: onProgress,
            ),
          )
        : LessonModel.fromDto(
            dto,
            audioPath: await _ensureAudioFile(audio, onProgress: onProgress),
          );
    await _local.upsertLesson(model);
    return model;
  }

  /// A server lesson keeping the files already downloaded for it: the file
  /// behind an `audio_id` never changes.
  LessonModel _withCachedAudio(LessonDto dto, LessonModel? cached) {
    final known = {
      for (final phrase in cached?.phrases ?? const <PhraseModel>[])
        if (phrase.audioPath.isNotEmpty) phrase.audio.id: phrase.audioPath,
    };
    final storyAudioId = dto.audio?.id;
    return LessonModel.fromDto(
      dto,
      audioPath: storyAudioId != null && cached?.audioId == storyAudioId
          ? cached?.audioPath ?? ''
          : '',
      phrases: [
        for (final phrase in dto.phrases)
          phrase.withAudioPath(known[phrase.audio.id] ?? ''),
      ],
    );
  }

  /// Downloads every distinct file of the phrases; [onProgress] counts them
  /// together.
  Future<List<PhraseModel>> _ensurePhraseFiles(
    List<PhraseModel> phrases, {
    void Function(int received, int total)? onProgress,
  }) async {
    final files = {for (final phrase in phrases) phrase.audio.id: phrase.audio};
    final total = files.values.fold(0, (sum, audio) => sum + audio.sizeBytes);
    final paths = <String, String>{};
    var done = 0;
    for (final audio in files.values) {
      final offset = done;
      paths[audio.id] = await _ensureAudioFile(
        audio,
        onProgress: onProgress == null
            ? null
            : (received, _) => onProgress(offset + received, total),
      );
      done += audio.sizeBytes;
    }
    return [
      for (final phrase in phrases)
        phrase.withAudioPath(paths[phrase.audio.id] ?? ''),
    ];
  }

  /// Path to the audio file: downloads a missing one and verifies `sha256`.
  Future<String> _ensureAudioFile(
    AudioDto audio, {
    void Function(int received, int total)? onProgress,
  }) async {
    final existing = await _cache.find(audio.id);
    if (existing != null) {
      if (await _cache.verify(existing, audio.sha256)) return existing;
      await _cache.remove(audio.id);
    }

    final target = await _cache.pathFor(audio.id, audio.fileExtension);
    await _audio.download(
      audioId: audio.id,
      targetPath: target,
      onProgress: onProgress,
    );
    if (!await _cache.verify(target, audio.sha256)) {
      await _cache.remove(audio.id);
      throw const AudioFailure(
        'The downloaded file is corrupted — try opening the lesson again',
      );
    }
    return target;
  }

  /// Downloads a voice sample into the temporary directory: it is a service
  /// phrase and has no place in the lesson audio cache.
  Future<String> _downloadSample(AudioDto audio) async {
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, _sampleDirName),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = p.join(dir.path, '${audio.id}.${audio.fileExtension}');
    // The same voice repeats often — a downloaded sample is enough.
    if (!await File(target).exists()) {
      await _audio.download(audioId: audio.id, targetPath: target);
    }
    return target;
  }

  /// Cached lesson when its audio is already downloaded.
  Future<Lesson> _cachedPlayable(String id) async {
    final cached = await _local.getLesson(id);
    if (cached == null) {
      throw const NetworkFailure(
        'No connection to the server, and this lesson is not downloaded yet',
      );
    }
    if (!cached.hasAudioFile || !await _allExist(cached.audioPaths)) {
      throw const NetworkFailure(
        'No connection to the server, and this lesson audio is not downloaded yet',
      );
    }
    return cached.toEntity();
  }

  Future<bool> _allExist(List<String> paths) async {
    for (final path in paths) {
      if (!await File(path).exists()) return false;
    }
    return true;
  }

  Future<void> _forget(String id) async {
    await _local.deleteLesson(id);
    await _tidyAudioCache();
  }

  /// Drops files no lesson refers to and shrinks the cache; downloaded
  /// lessons keep their audio.
  Future<void> _tidyAudioCache() async {
    final used = await _local.usedAudioIds();
    await _cache.retainOnly(used);
    await _cache.trimToSize(_maxCacheBytes, keep: await _downloadedAudioIds());
  }

  Future<Set<String>> _downloadedAudioIds() async {
    final downloaded = await _local.downloadedIds();
    if (downloaded.isEmpty) return const {};
    return {
      for (final lesson in await _local.getLessons())
        if (downloaded.contains(lesson.id)) ...lesson.audioIds,
    };
  }

  /// An empty cached string means the value is absent.
  static String? _nullIfEmpty(String value) => value.isEmpty ? null : value;

  static String? _laterOf(String? current, DateTime candidate) {
    final value = candidate.toUtc().toIso8601String();
    if (current == null) return value;
    return value.compareTo(current) > 0 ? value : current;
  }
}
