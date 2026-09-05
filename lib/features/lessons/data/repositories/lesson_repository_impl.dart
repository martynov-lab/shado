import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/audio_upload.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/entities/tts_quota.dart';
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
  Future<void> syncLessons() async {
    final since = await _local.readSyncWatermark();
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
        final cached = await _local.getLesson(dto.id);
        fresh.add(
          LessonModel.fromDto(
            dto,
            // The file behind an `audio_id` never changes: keep it.
            audioPath: cached?.audioId == dto.audio.id
                ? cached?.audioPath ?? ''
                : '',
          ),
        );
      }
      cursor = page.nextCursor;
    } while (cursor != null);

    await _local.deleteLessons(removed);
    await _local.upsertAll(fresh);
    // The watermark is the max `updated_at` of the response, not device time.
    if (watermark != null) await _local.writeSyncWatermark(watermark);
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

    final audioPath = await _ensureAudioFile(dto.audio);
    final model = LessonModel.fromDto(dto, audioPath: audioPath);
    await _local.upsertLesson(model);
    return model.toEntity();
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
    Object? cancel,
  }) async {
    final dto = await _tts.synthesize(
      text: text,
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
  Future<TtsQuota> ttsQuota() => _tts.quota();

  @override
  Future<List<Topic>> getTopics() => _topics.list();

  @override
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
    final audioPath = await _ensureAudioFile(dto.audio);
    final model = LessonModel.fromDto(dto, audioPath: audioPath);
    await _local.upsertLesson(model);
    return model.toEntity();
  }

  @override
  Future<void> updateLesson(Lesson lesson, {bool? isPublic}) async {
    final cached = await _local.getLesson(lesson.id);
    if (cached == null) {
      throw NotFoundFailure('Урок ${lesson.id} не найден в кеше');
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
        accent: lesson.accent ?? LessonAccent.parse(cached.accent),
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

  /// Path to the audio file: downloads a missing one and verifies `sha256`.
  Future<String> _ensureAudioFile(AudioDto audio) async {
    final existing = await _cache.find(audio.id);
    if (existing != null) {
      if (await _cache.verify(existing, audio.sha256)) return existing;
      await _cache.remove(audio.id);
    }

    final target = await _cache.pathFor(audio.id, audio.fileExtension);
    await _audio.download(audioId: audio.id, targetPath: target);
    if (!await _cache.verify(target, audio.sha256)) {
      await _cache.remove(audio.id);
      throw const AudioFailure(
        'Скачанный файл повреждён — попробуйте открыть урок ещё раз',
      );
    }
    return target;
  }

  /// Cached lesson when its audio is already downloaded.
  Future<Lesson?> _cachedPlayable(String id) async {
    final cached = await _local.getLesson(id);
    if (cached == null) return null;
    if (!cached.hasAudioFile || !await File(cached.audioPath).exists()) {
      throw const NetworkFailure(
        'Нет связи с сервером, а аудио этого урока ещё не скачано',
      );
    }
    return cached.toEntity();
  }

  Future<void> _forget(String id) async {
    await _local.deleteLesson(id);
    await _tidyAudioCache();
  }

  /// Drops files no lesson refers to and shrinks the cache.
  Future<void> _tidyAudioCache() async {
    final used = await _local.usedAudioIds();
    await _cache.retainOnly(used);
    await _cache.trimToSize(_maxCacheBytes);
  }

  /// An empty cached string means the value is absent.
  static String? _nullIfEmpty(String value) => value.isEmpty ? null : value;

  static String? _laterOf(String? current, DateTime candidate) {
    final value = candidate.toUtc().toIso8601String();
    if (current == null) return value;
    return value.compareTo(current) > 0 ? value : current;
  }
}
