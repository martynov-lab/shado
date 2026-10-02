import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/platform_setup.dart';
import '../../domain/entities/folder.dart';
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

  /// Lessons the user downloaded for offline study.
  static const String _downloadsTable = 'downloads';

  /// Folders as last fetched; `lesson_ids` is set once the folder was opened.
  static const String _foldersTable = 'folders';

  /// Library root items in server order.
  static const String _libraryTable = 'library_root';
  static const String _folderKind = 'folder';
  static const String _lessonKind = 'lesson';

  /// Delta watermark key; a shared one would half-load a switched catalog.
  static String _watermarkKey(String language) =>
      language.isEmpty ? 'lessons_updated_at' : 'lessons_updated_at_$language';

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
        version: 7,
        onCreate: (db, version) => _createSchema(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          // The cache is recreated, not migrated; `syncLessons` refills it.
          await db.execute('DROP TABLE IF EXISTS $_table');
          await _createSchema(db);
          // Reset the sync watermark too, otherwise only a delta would arrive.
          await db.delete(_metaTable);
          await db.delete(_downloadsTable);
          await db.delete(_foldersTable);
          await db.delete(_libraryTable);
        },
      );
      _database = db;
      return db;
    } catch (error, stackTrace) {
      _opening = null;
      Error.throwWithStackTrace(
        StorageFailure('Failed to open the database', cause: error),
        stackTrace,
      );
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
        language TEXT NOT NULL DEFAULT '',
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_downloadsTable (
        lesson_id TEXT PRIMARY KEY,
        downloaded_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_foldersTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL,
        is_public INTEGER NOT NULL,
        language TEXT NOT NULL,
        lesson_count INTEGER NOT NULL,
        lesson_ids TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_libraryTable (
        position INTEGER PRIMARY KEY,
        kind TEXT NOT NULL,
        item_id TEXT NOT NULL
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the lesson list', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read lesson $id', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the lesson', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the lessons', cause: error),
        stackTrace,
      );
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
      await db.delete(
        _downloadsTable,
        where: 'lesson_id IN ($placeholders)',
        whereArgs: list,
      );
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to delete the lessons', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the lesson cache', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<Set<String>> downloadedIds() async {
    try {
      final db = await _db();
      final rows = await db.query(_downloadsTable, columns: ['lesson_id']);
      return {
        for (final row in rows)
          if (row['lesson_id'] case final String id) id,
      };
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the downloaded lessons', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> markDownloaded(String id) async {
    try {
      final db = await _db();
      await db.insert(_downloadsTable, {
        'lesson_id': id,
        'downloaded_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to mark the lesson downloaded', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> unmarkDownloaded(String id) async {
    try {
      final db = await _db();
      await db.delete(_downloadsTable, where: 'lesson_id = ?', whereArgs: [id]);
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to remove the download mark', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<({List<Folder> folders, List<String> lessonIds})?>
  readLibrary() async {
    try {
      final db = await _db();
      final items = await db.query(_libraryTable, orderBy: 'position');
      if (items.isEmpty) return null;
      final folders = {
        for (final row in await db.query(_foldersTable))
          row['id']! as String: _folderFromRow(row),
      };
      return (
        folders: [
          for (final item in items)
            if (item['kind'] == _folderKind)
              ?folders[item['item_id']! as String],
        ],
        lessonIds: [
          for (final item in items)
            if (item['kind'] == _lessonKind) item['item_id']! as String,
        ],
      );
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the saved library', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> writeLibrary({
    required List<Folder> folders,
    required List<String> lessonIds,
  }) async {
    try {
      final db = await _db();
      await db.transaction((txn) async {
        await txn.delete(_libraryTable);
        var position = 0;
        for (final folder in folders) {
          await _upsertFolderMeta(txn, folder);
          await txn.insert(_libraryTable, {
            'position': position++,
            'kind': _folderKind,
            'item_id': folder.id,
          });
        }
        for (final id in lessonIds) {
          await txn.insert(_libraryTable, {
            'position': position++,
            'kind': _lessonKind,
            'item_id': id,
          });
        }
      });
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the library', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<({Folder folder, List<String> lessonIds})?> readFolder(
    String id,
  ) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _foldersTable,
        where: 'id = ? AND lesson_ids IS NOT NULL',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      return (
        folder: _folderFromRow(row),
        lessonIds: [
          for (final lessonId
              in jsonDecode(row['lesson_ids']! as String) as List)
            lessonId as String,
        ],
      );
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read folder $id', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> writeFolder(Folder folder) async {
    try {
      final db = await _db();
      await db.insert(_foldersTable, {
        ..._folderMetaRow(folder),
        'lesson_ids': jsonEncode([
          for (final lesson in folder.lessons) lesson.id,
        ]),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the folder', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    try {
      final db = await _db();
      await db.delete(_foldersTable, where: 'id = ?', whereArgs: [id]);
      await db.delete(
        _libraryTable,
        where: 'kind = ? AND item_id = ?',
        whereArgs: [_folderKind, id],
      );
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to delete the saved folder', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<String?> readSyncWatermark(String language) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _metaTable,
        where: 'key = ?',
        whereArgs: [_watermarkKey(language)],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['value'] as String?;
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the sync marker', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> writeSyncWatermark(String language, String updatedAt) async {
    try {
      final db = await _db();
      await db.insert(_metaTable, {
        'key': _watermarkKey(language),
        'value': updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the sync marker', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      final db = await _db();
      await db.delete(_table);
      await db.delete(_metaTable);
      await db.delete(_downloadsTable);
      await db.delete(_foldersTable);
      await db.delete(_libraryTable);
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to clear the lesson cache', cause: error),
        stackTrace,
      );
    }
  }

  /// Updates folder fields and keeps its saved lesson ids.
  Future<void> _upsertFolderMeta(DatabaseExecutor db, Folder folder) async {
    final row = _folderMetaRow(folder);
    final updated = await db.update(
      _foldersTable,
      row,
      where: 'id = ?',
      whereArgs: [folder.id],
    );
    if (updated == 0) await db.insert(_foldersTable, row);
  }

  Map<String, Object?> _folderMetaRow(Folder folder) => {
    'id': folder.id,
    'title': folder.title,
    'created_at': folder.createdAt.toUtc().toIso8601String(),
    'updated_at': folder.updatedAt.toUtc().toIso8601String(),
    'version': folder.version,
    'is_public': folder.isPublic ? 1 : 0,
    'language': folder.language,
    'lesson_count': folder.lessonCount,
  };

  Folder _folderFromRow(Map<String, Object?> row) => Folder(
    id: row['id']! as String,
    title: row['title']! as String,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    version: row['version']! as int,
    isPublic: (row['is_public']! as int) != 0,
    language: row['language']! as String,
    lessonCount: row['lesson_count']! as int,
  );

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
    'language': lesson.language,
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
      language: row['language'] as String? ?? '',
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
