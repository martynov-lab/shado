import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/failures.dart';
import '../models/lesson_model.dart';
import '../models/segment_model.dart';
import 'lesson_local_datasource.dart';

/// Реализация на sqflite. Сегменты хранятся JSON-колонкой урока: они часть
/// агрегата и всегда читаются/пишутся вместе с ним.
class SqfliteLessonLocalDataSource implements LessonLocalDataSource {
  SqfliteLessonLocalDataSource({String databaseName = 'shado.db'})
    : _databaseName = databaseName;

  static const String _table = 'lessons';

  final String _databaseName;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> _db() {
    final db = _database;
    if (db != null) return Future.value(db);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final path = p.join(await getDatabasesPath(), _databaseName);
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              audio_path TEXT NOT NULL,
              duration_ms INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              segments TEXT NOT NULL
            )
          ''');
        },
      );
      _database = db;
      return db;
    } catch (error) {
      _opening = null;
      throw StorageFailure('Не удалось открыть базу данных', cause: error);
    }
  }

  @override
  Future<List<LessonModel>> getLessons() async {
    try {
      final db = await _db();
      final rows = await db.query(_table, orderBy: 'created_at DESC');
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
  Future<void> deleteLesson(String id) async {
    try {
      final db = await _db();
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } on Failure {
      rethrow;
    } catch (error) {
      throw StorageFailure('Не удалось удалить урок $id', cause: error);
    }
  }

  Map<String, Object?> _toRow(LessonModel lesson) => {
    'id': lesson.id,
    'title': lesson.title,
    'audio_path': lesson.audioPath,
    'duration_ms': lesson.durationMs,
    'created_at': lesson.createdAt.toUtc().toIso8601String(),
    'segments': jsonEncode(
      lesson.segments.map((segment) => segment.toJson()).toList(),
    ),
  };

  LessonModel _fromRow(Map<String, Object?> row) {
    final rawSegments = jsonDecode(row['segments']! as String) as List<dynamic>;
    return LessonModel(
      id: row['id']! as String,
      title: row['title']! as String,
      audioPath: row['audio_path']! as String,
      durationMs: row['duration_ms']! as int,
      createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
      segments: rawSegments
          .map((json) => SegmentModel.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }
}
