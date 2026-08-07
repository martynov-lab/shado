import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/platform_setup.dart';
import 'progress_local_datasource.dart';

/// Реализация на sqflite. Отдельная БД `progress.db`, миграции только
/// аддитивные: минуты и повторы — не кеш, их нельзя пересоздать с сервера.
class SqfliteProgressLocalDataSource implements ProgressLocalDataSource {
  SqfliteProgressLocalDataSource({String databaseName = 'progress.db'})
    : _databaseName = databaseName;

  static const String _repsTable = 'segment_reps';
  static const String _lessonTable = 'lesson_progress';
  static const String _pendingTable = 'pending';

  final String _databaseName;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> _db() {
    final db = _database;
    if (db != null) return Future.value(db);
    return _opening ??= _open();
  }

  /// Каталог БД — тот же приём, что у кеша уроков: FFI-фабрика на десктопе иначе
  /// кладёт файл в `.dart_tool`.
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
        version: 1,
        onCreate: (db, version) => _createSchema(db),
        // Только аддитивно: существующие данные не трогаем.
        onUpgrade: (db, oldVersion, newVersion) => _createSchema(db),
      );
      _database = db;
      return db;
    } catch (error) {
      _opening = null;
      throw StorageFailure('Не удалось открыть базу прогресса', cause: error);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_repsTable (
        lesson_id TEXT NOT NULL,
        segment_index INTEGER NOT NULL,
        reps INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (lesson_id, segment_index)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_lessonTable (
        lesson_id TEXT PRIMARY KEY,
        completed_sent INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_pendingTable (
        id INTEGER PRIMARY KEY,
        listened_ms INTEGER NOT NULL DEFAULT 0,
        segment_repeats INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Единственная строка-аккумулятор: заводим сразу, дальше только UPDATE.
    await db.insert(_pendingTable, {
      'id': 1,
      'listened_ms': 0,
      'segment_repeats': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> bumpSegment(String lessonId, int segmentIndex) async {
    try {
      final db = await _db();
      await db.transaction((txn) async {
        // Повтор конкретного сегмента (для «пройдено» и прогресс-бара).
        await txn.rawInsert(
          'INSERT INTO $_repsTable (lesson_id, segment_index, reps) '
          'VALUES (?, ?, 1) '
          'ON CONFLICT(lesson_id, segment_index) DO UPDATE SET reps = reps + 1',
          [lessonId, segmentIndex],
        );
        // И в дневную дельту для сервера.
        await txn.rawUpdate(
          'UPDATE $_pendingTable SET segment_repeats = segment_repeats + 1 '
          'WHERE id = 1',
        );
      });
    } catch (error) {
      throw StorageFailure('Не удалось записать повтор сегмента', cause: error);
    }
  }

  @override
  Future<void> addListened(int ms) async {
    if (ms <= 0) return;
    try {
      final db = await _db();
      await db.rawUpdate(
        'UPDATE $_pendingTable SET listened_ms = listened_ms + ? WHERE id = 1',
        [ms],
      );
    } catch (error) {
      throw StorageFailure('Не удалось записать минуты', cause: error);
    }
  }

  @override
  Future<Map<int, int>> readReps(String lessonId) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _repsTable,
        columns: ['segment_index', 'reps'],
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
      );
      return {
        for (final row in rows)
          row['segment_index']! as int: row['reps']! as int,
      };
    } catch (error) {
      throw StorageFailure('Не удалось прочитать повторы', cause: error);
    }
  }

  @override
  Future<PendingEvents> readPending() async {
    try {
      final db = await _db();
      final rows = await db.query(_pendingTable, where: 'id = 1', limit: 1);
      if (rows.isEmpty) return PendingEvents.empty;
      return PendingEvents(
        listenedMs: rows.first['listened_ms'] as int? ?? 0,
        segmentRepeats: rows.first['segment_repeats'] as int? ?? 0,
      );
    } catch (error) {
      throw StorageFailure('Не удалось прочитать дельту', cause: error);
    }
  }

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) async {
    try {
      final db = await _db();
      // MAX(0, …): активность во время запроса не уводит счётчик в минус.
      await db.rawUpdate(
        'UPDATE $_pendingTable SET '
        'listened_ms = MAX(0, listened_ms - ?), '
        'segment_repeats = MAX(0, segment_repeats - ?) '
        'WHERE id = 1',
        [listenedMs, segmentRepeats],
      );
    } catch (error) {
      throw StorageFailure('Не удалось обновить дельту', cause: error);
    }
  }

  @override
  Future<bool> isCompletedSent(String lessonId) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _lessonTable,
        columns: ['completed_sent'],
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      return (rows.first['completed_sent'] as int? ?? 0) != 0;
    } catch (error) {
      throw StorageFailure('Не удалось прочитать флаг пройдено', cause: error);
    }
  }

  @override
  Future<void> markCompletedSent(String lessonId) async {
    try {
      final db = await _db();
      await db.insert(_lessonTable, {
        'lesson_id': lessonId,
        'completed_sent': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error) {
      throw StorageFailure('Не удалось отметить пройдено', cause: error);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final db = await _db();
      await db.delete(_repsTable);
      await db.delete(_lessonTable);
      await db.update(_pendingTable, {
        'listened_ms': 0,
        'segment_repeats': 0,
      }, where: 'id = 1');
    } catch (error) {
      throw StorageFailure('Не удалось очистить прогресс', cause: error);
    }
  }
}
