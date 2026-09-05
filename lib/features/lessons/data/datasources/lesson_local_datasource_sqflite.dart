import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/platform_setup.dart';
import '../models/lesson_model.dart';
import '../models/segment_model.dart';
import 'lesson_local_datasource.dart';

/// Sqflite lesson cache; segments live in a JSON column of the lesson.
class SqfliteLessonLocalDataSource implements LessonLocalDataSource {
  SqfliteLessonLocalDataSource({String databaseName = 'shado.db'})
    : _databaseName = databaseName;

  static const String _table = 'lessons';

  /// Table of cache service values.
  static const String _metaTable = 'sync_meta';
  static const String _watermarkKey = 'lessons_updated_at';

  final String _databaseName;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> _db() {
    final db = _database;
    if (db != null) return Future.value(db);
    return _opening ??= _open();
  }

  /// Database file directory; on desktop the documents folder, as for audio.
  Future<String> _databaseDirectory() async {
    if (!isPluginlessDesktop) return getDatabasesPath();
    final documents = await getApplicationDocumentsDirectory();
    return documents.path;
  }

  Future<Database> _open() async {
    try {
      final path = p.join(await _databaseDirectory(), _databaseName);
      final db = await openDatabase(
        path,
        version: 4,
        onCreate: (db, version) => _createSchema(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          // The cache is recreated, not migrated; `syncLessons` refills it.
          await db.execute('DROP TABLE IF EXISTS $_table');
          await _createSchema(db);
          // Reset the sync watermark too, otherwise only a delta would arrive.
          await db.delete(_metaTable);
        },
      );
      _database = db;
      return db;
    } catch (error) {
      _opening = null;
      throw StorageFailure('Не удалось открыть базу данных', cause: error);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        audio_id TEXT NOT NULL,
        audio_path TEXT NOT NULL,
        audio_sha256 TEXT NOT NULL DEFAULT '',
        audio_content_type TEXT NOT NULL DEFAULT '',
        duration_ms INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_public INTEGER NOT NULL DEFAULT 1,
        accent TEXT NOT NULL DEFAULT '',
        level TEXT NOT NULL DEFAULT '',
        topic_id TEXT NOT NULL DEFAULT '',
        topic_name TEXT NOT NULL DEFAULT '',
        segments TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_metaTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<List<LessonModel>> getLessons() async {
    try {
      final db = await _db();
      // Same order as the server: newest edits first.
      final rows = await db.query(_table, orderBy: 'updated_at DESC');
      return rows.map(_fromRow).toList(growable: false);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось прочитать список уроков', cause: error);
    }
  }

  @override
  Future<LessonModel?> getLesson(String id) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _fromRow(rows.first);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось прочитать урок $id', cause: error);
    }
  }

  @override
  Future<void> upsertLesson(LessonModel lesson) async {
    try {
      final db = await _db();
      await db.insert(
        _table,
        _toRow(lesson),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось сохранить урок', cause: error);
    }
  }

  @override
  Future<void> upsertAll(List<LessonModel> lessons) async {
    if (lessons.isEmpty) return;
    try {
      final db = await _db();
      final batch = db.batch();
      for (final lesson in lessons) {
        batch.insert(
          _table,
          _toRow(lesson),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось сохранить уроки', cause: error);
    }
  }

  @override
  Future<void> deleteLesson(String id) => deleteLessons([id]);

  @override
  Future<void> deleteLessons(Iterable<String> ids) async {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return;
    try {
      final db = await _db();
      final placeholders = List.filled(list.length, '?').join(', ');
      await db.delete(_table, where: 'id IN ($placeholders)', whereArgs: list);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось удалить уроки', cause: error);
    }
  }

  @override
  Future<Set<String>> usedAudioIds() async {
    try {
      final db = await _db();
      final rows = await db.query(
        _table,
        columns: ['audio_id'],
        distinct: true,
      );
      return {
        for (final row in rows)
          if (row['audio_id'] case final String id) id,
      };
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось прочитать кеш уроков', cause: error);
    }
  }

  @override
  Future<String?> readSyncWatermark() async {
    try {
      final db = await _db();
      final rows = await db.query(
        _metaTable,
        where: 'key = ?',
        whereArgs: [_watermarkKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['value'] as String?;
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure(
        'Не удалось прочитать метку синхронизации',
        cause: error,
      );
    }
  }

  @override
  Future<void> writeSyncWatermark(String updatedAt) async {
    try {
      final db = await _db();
      await db.insert(_metaTable, {
        'key': _watermarkKey,
        'value': updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure(
        'Не удалось сохранить метку синхронизации',
        cause: error,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      final db = await _db();
      await db.delete(_table);
      await db.delete(_metaTable);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось очистить кеш уроков', cause: error);
    }
  }

  Map<String, Object?> _toRow(LessonModel lesson) => {
    'id': lesson.id,
    'title': lesson.title,
    'audio_id': lesson.audioId,
    'audio_path': lesson.audioPath,
    'audio_sha256': lesson.audioSha256,
    'audio_content_type': lesson.audioContentType,
    'duration_ms': lesson.durationMs,
    'created_at': lesson.createdAt.toUtc().toIso8601String(),
    'updated_at': lesson.updatedAt.toUtc().toIso8601String(),
    'version': lesson.version,
    'is_public': lesson.isPublic ? 1 : 0,
    'accent': lesson.accent,
    'level': lesson.level,
    'topic_id': lesson.topicId,
    'topic_name': lesson.topicName,
    'segments': jsonEncode(
      lesson.segments.map((segment) => segment.toJson()).toList(),
    ),
  };

  LessonModel _fromRow(Map<String, Object?> row) {
    final rawSegments = jsonDecode(row['segments']! as String) as List<dynamic>;
    return LessonModel(
      id: row['id']! as String,
      title: row['title']! as String,
      audioId: row['audio_id']! as String,
      audioPath: row['audio_path']! as String,
      audioSha256: row['audio_sha256'] as String? ?? '',
      audioContentType: row['audio_content_type'] as String? ?? '',
      durationMs: row['duration_ms']! as int,
      createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
      version: row['version'] as int? ?? 1,
      isPublic: (row['is_public'] as int? ?? 1) != 0,
      accent: row['accent'] as String? ?? '',
      level: row['level'] as String? ?? '',
      topicId: row['topic_id'] as String? ?? '',
      topicName: row['topic_name'] as String? ?? '',
      segments: rawSegments
          .map((json) => SegmentModel.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }
}
