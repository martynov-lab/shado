import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/audio_upload.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/audio_cache.dart';
import '../datasources/audio_remote_datasource.dart';
import '../datasources/lesson_local_datasource.dart';
import '../datasources/lesson_remote_datasource.dart';
import '../models/audio_dto.dart';
import '../models/lesson_dto.dart';
import '../models/lesson_model.dart';
import '../models/segment_model.dart';

/// Сервер — источник истины, sqflite — кеш для чтения, файлы аудио — кеш по
/// `audio_id`.
///
/// Наружу репозиторий отдаёт ровно то же, что и раньше: урок с локальным путём
/// к аудио. Всё, что для этого нужно сделать по сети, происходит здесь.
class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl({
    required LessonLocalDataSource localDataSource,
    required LessonRemoteDataSource remoteDataSource,
    required AudioRemoteDataSource audioDataSource,
    required AudioCache audioCache,
    Uuid uuid = const Uuid(),
  }) : _local = localDataSource,
       _remote = remoteDataSource,
       _audio = audioDataSource,
       _cache = audioCache,
       _uuid = uuid;

  /// Сколько места отдаём под скачанное аудио. Свыше — вытесняем давно не
  /// открывавшиеся уроки, они докачаются, когда к ним вернутся.
  static const int _maxCacheBytes = 2 * 1024 * 1024 * 1024;

  /// Размер страницы списка. Сервер отдаёт максимум 200 за раз.
  static const int _pageLimit = 100;

  final LessonLocalDataSource _local;
  final LessonRemoteDataSource _remote;
  final AudioRemoteDataSource _audio;
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
      // Без `since` сервер отдаёт только живые уроки — так идёт первый запуск.
      // С `since` приходит дельта, и в ней есть удалённые: только по ним видно,
      // что урок стёрли на другом устройстве.
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
            // Файл под тем же `audio_id` не меняется никогда, поэтому уже
            // скачанное остаётся на месте.
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
    // Метка — максимальный `updated_at` из полученного, а не текущее время:
    // часы устройства могут врать, и тогда часть правок потерялась бы навсегда.
    if (watermark != null) await _local.writeSyncWatermark(watermark);
    await _tidyAudioCache();
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    final LessonDto dto;
    try {
      dto = await _remote.getLesson(id);
    } on ApiException catch (error) {
      // Урока нет или он чужой — в обоих случаях его надо убрать из кеша.
      if (error.isNotFound) {
        await _forget(id);
        return null;
      }
      rethrow;
    } on NetworkFailure {
      // Сети нет: отдаём последнее известное, если аудио уже скачано.
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
    // Файл уже здесь — кладём его в кеш сразу, качать обратно после создания
    // урока незачем.
    await _cache.put(
      audioId: dto.id,
      extension: dto.fileExtension,
      sourcePath: filePath,
    );
    return AudioUpload(
      audioId: dto.id,
      durationMs: dto.durationMs,
      sizeBytes: dto.sizeBytes,
    );
  }

  @override
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    List<int>? boundaries,
  }) async {
    // UUID генерит клиент, поэтому повтор `PUT` после потери сети не создаёт
    // дубль.
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
    );
    final audioPath = await _ensureAudioFile(dto.audio);
    final model = LessonModel.fromDto(dto, audioPath: audioPath);
    await _local.upsertLesson(model);
    return model.toEntity();
  }

  @override
  Future<void> updateLesson(Lesson lesson) async {
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
        // Версия из кеша: правка идёт поверх того, что мы последний раз видели.
        version: cached.version,
      );
      await _local.upsertLesson(
        LessonModel.fromDto(dto, audioPath: cached.audioPath),
      );
    } on ApiException catch (error) {
      final current = error.current;
      if (!error.isVersionConflict || current == null) rethrow;
      // Урок правили на другом устройстве. Свежую версию кладём в кеш, чтобы
      // пользователю было что переписать, а сам конфликт показываем ему.
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
      // Удалять то, чего нет, — успех: локально запись всё равно уходит.
      if (!error.isNotFound) rethrow;
    }
    await _forget(id);
  }

  @override
  Future<void> clearCache() async {
    await _local.clear();
    await _cache.clear();
  }

  /// Сегменты для сервера.
  ///
  /// Сервер требует, чтобы куски покрывали файл целиком (`0..duration_ms`),
  /// поэтому крайние границы прижимаются к краям файла: обрезка остаётся
  /// инструментом разметки на клиенте и на сервер не уезжает.
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

  /// Возвращает путь к готовому к воспроизведению файлу, докачивая его при
  /// необходимости.
  ///
  /// Целостность проверяем по `sha256`: недокачанный или битый файл удаляем и
  /// качаем заново, иначе плеер молча споткнётся на нём позже.
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

  /// Урок из кеша, но только если его аудио на месте: без файла экран урока
  /// всё равно ничего не сыграет.
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

  /// Убирает файлы, на которые не ссылается ни один урок, и ужимает кеш.
  ///
  /// Осторожно с удалением «аудио удалённого урока»: сервер дедуплицирует
  /// загрузки по sha256, поэтому один `audio_id` может быть у нескольких
  /// уроков сразу.
  Future<void> _tidyAudioCache() async {
    final used = await _local.usedAudioIds();
    await _cache.retainOnly(used);
    await _cache.trimToSize(_maxCacheBytes);
  }

  static String? _laterOf(String? current, DateTime candidate) {
    final value = candidate.toUtc().toIso8601String();
    if (current == null) return value;
    return value.compareTo(current) > 0 ? value : current;
  }
}
