import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/platform_setup.dart';
import '../../domain/entities/item_rating.dart';
import '../../domain/entities/pending_events.dart';
import '../../domain/entities/progress_summary.dart';
import 'progress_local_datasource.dart';

/// Sqflite implementation backed by a separate `progress.db`; migrations are
/// additive only, since minutes and repeats cannot be refetched.
class SqfliteProgressLocalDataSource implements ProgressLocalDataSource {
  SqfliteProgressLocalDataSource({String databaseName = 'progress.db'})
    : _databaseName = databaseName;

  static const String _lessonTable = 'lesson_progress';
  static const String _ratingsTable = 'ratings';
  static const String _pendingTable = 'pending';

  /// Last server responses as JSON, shown while offline.
  static const String _snapshotsTable = 'snapshots';
  static const String _summaryKey = 'summary';
  static const String _historyKey = 'history';
  static const String _ratingsSinceKey = 'ratings_since';

  final String _databaseName;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> _db() {
    final db = _database;
    if (db != null) return Future.value(db);
    return _opening ??= _open();
  }

  /// Database directory; the desktop FFI factory would otherwise put the file
  /// into `.dart_tool`.
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
        version: 3,
        onCreate: (db, version) => _createSchema(db),
        // Additive only: existing data is left untouched.
        onUpgrade: (db, oldVersion, newVersion) => _createSchema(db),
      );
      _database = db;
      return db;
    } catch (error, stackTrace) {
      _opening = null;
      Error.throwWithStackTrace(
        StorageFailure('Failed to open the progress database', cause: error),
        stackTrace,
      );
    }
  }

  Future<void> _createSchema(Database db) async {
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
    // Star ratings; `queued` marks the ones the server has not received yet.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_ratingsTable (
        lesson_id TEXT NOT NULL,
        item_key TEXT NOT NULL,
        stars INTEGER NOT NULL,
        rated_at TEXT NOT NULL,
        queued INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (lesson_id, item_key)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_snapshotsTable (
        key TEXT PRIMARY KEY,
        json TEXT NOT NULL
      )
    ''');
    // A single accumulator row: created once, updated afterwards.
    await db.insert(_pendingTable, {
      'id': 1,
      'listened_ms': 0,
      'segment_repeats': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> bumpSegment() async {
    try {
      final db = await _db();
      await db.rawUpdate(
        'UPDATE $_pendingTable SET segment_repeats = segment_repeats + 1 '
        'WHERE id = 1',
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to record the segment repeat', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to record the minutes', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<Map<String, int>> readStars(String lessonId) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _ratingsTable,
        columns: ['item_key', 'stars'],
        where: 'lesson_id = ? AND stars > 0',
        whereArgs: [lessonId],
      );
      return {
        for (final row in rows) row['item_key']! as String: row['stars']! as int,
      };
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the ratings', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> saveRatings(List<ItemRating> ratings) async {
    try {
      final db = await _db();
      final batch = db.batch();
      for (final rating in ratings) {
        batch.insert(_ratingsTable, {
          ..._ratingRow(rating),
          'queued': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the rating', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<List<ItemRating>> readQueuedRatings({required int limit}) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _ratingsTable,
        where: 'queued = 1',
        orderBy: 'rated_at',
        limit: limit,
      );
      return [for (final row in rows) _ratingOf(row)];
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the ratings', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> markRatingsSent(List<ItemRating> sent) async {
    try {
      final db = await _db();
      final batch = db.batch();
      for (final rating in sent) {
        // A rating changed during the request keeps waiting for its turn.
        batch.update(
          _ratingsTable,
          {'queued': 0},
          where: 'lesson_id = ? AND item_key = ? AND rated_at = ?',
          whereArgs: [
            rating.lessonId,
            rating.itemKey,
            _timeOf(rating.ratedAt),
          ],
        );
      }
      await batch.commit(noResult: true);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to update the ratings', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<Set<String>> applyServerRatings(List<ItemRating> ratings) async {
    if (ratings.isEmpty) return const {};
    try {
      final db = await _db();
      final changed = <String>{};
      await db.transaction((txn) async {
        for (final rating in ratings) {
          final rows = await txn.query(
            _ratingsTable,
            columns: ['stars', 'rated_at'],
            where: 'lesson_id = ? AND item_key = ?',
            whereArgs: [rating.lessonId, rating.itemKey],
            limit: 1,
          );
          if (rows.isNotEmpty) {
            final local = DateTime.parse(rows.first['rated_at']! as String);
            // The later rating wins; an equal one is already applied.
            if (!rating.ratedAt.isAfter(local)) continue;
          }
          await txn.insert(_ratingsTable, {
            ..._ratingRow(rating),
            'queued': 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          if (rows.isEmpty || rows.first['stars'] != rating.stars) {
            changed.add(rating.lessonId);
          }
        }
      });
      return changed;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the ratings', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<String?> readRatingsSince() async {
    final json = await _readSnapshot(_ratingsSinceKey);
    return json is String ? json : null;
  }

  @override
  Future<void> saveRatingsSince(String serverTime) =>
      _writeSnapshot(_ratingsSinceKey, serverTime);

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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the delta', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) async {
    try {
      final db = await _db();
      // MAX(0, …) keeps activity during the request from going negative.
      await db.rawUpdate(
        'UPDATE $_pendingTable SET '
        'listened_ms = MAX(0, listened_ms - ?), '
        'segment_repeats = MAX(0, segment_repeats - ?) '
        'WHERE id = 1',
        [listenedMs, segmentRepeats],
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to update the delta', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the completed flag', cause: error),
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to mark as completed', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<ProgressSummary?> readSummary() async {
    final json = await _readSnapshot(_summaryKey);
    return json is Map<String, dynamic> ? ProgressSummary.fromJson(json) : null;
  }

  @override
  Future<void> saveSummary(ProgressSummary summary) =>
      _writeSnapshot(_summaryKey, summary.toJson());

  @override
  Future<List<ProgressDay>?> readHistory() async {
    final json = await _readSnapshot(_historyKey);
    if (json is! List<dynamic>) return null;
    return [
      for (final day in json)
        ProgressDay.fromJson(Map<String, dynamic>.from(day as Map)),
    ];
  }

  @override
  Future<void> saveHistory(List<ProgressDay> days) =>
      _writeSnapshot(_historyKey, [for (final day in days) day.toJson()]);

  @override
  Future<void> clear() async {
    try {
      final db = await _db();
      await db.delete(_lessonTable);
      await db.delete(_ratingsTable);
      await db.delete(_snapshotsTable);
      await db.update(_pendingTable, {
        'listened_ms': 0,
        'segment_repeats': 0,
      }, where: 'id = 1');
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to clear the progress', cause: error),
        stackTrace,
      );
    }
  }

  Map<String, Object?> _ratingRow(ItemRating rating) => {
    'lesson_id': rating.lessonId,
    'item_key': rating.itemKey,
    'stars': rating.stars,
    'rated_at': _timeOf(rating.ratedAt),
  };

  ItemRating _ratingOf(Map<String, Object?> row) => ItemRating(
    lessonId: row['lesson_id']! as String,
    itemKey: row['item_key']! as String,
    stars: row['stars']! as int,
    ratedAt: DateTime.parse(row['rated_at']! as String),
  );

  /// UTC ISO-8601 that sorts lexicographically in time order.
  String _timeOf(DateTime time) => time.toUtc().toIso8601String();

  /// Decoded JSON stored under [key]; `null` when absent.
  Future<Object?> _readSnapshot(String key) async {
    try {
      final db = await _db();
      final rows = await db.query(
        _snapshotsTable,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['json']! as String);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to read the saved progress', cause: error),
        stackTrace,
      );
    }
  }

  Future<void> _writeSnapshot(String key, Object json) async {
    try {
      final db = await _db();
      await db.insert(_snapshotsTable, {
        'key': key,
        'json': jsonEncode(json),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageFailure('Failed to save the progress', cause: error),
        stackTrace,
      );
    }
  }
}
