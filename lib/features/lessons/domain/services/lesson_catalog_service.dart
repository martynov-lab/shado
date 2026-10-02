import 'dart:async';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../entities/lesson.dart';
import '../entities/library_root.dart';
import '../usecases/delete_lesson.dart';
import '../usecases/get_lessons.dart';
import '../usecases/get_library.dart';
import '../usecases/sync_lessons.dart';

/// The lesson catalog shared by the home, lessons, progress and folder
/// screens: every lesson of the studied language and the library root.
class LessonCatalogService {
  LessonCatalogService({
    required GetLessons getLessons,
    required SyncLessons syncLessons,
    required DeleteLesson deleteLesson,
    required GetLibrary getLibrary,
    required AuthService auth,
  }) : _getLessons = getLessons,
       _syncLessons = syncLessons,
       _deleteLesson = deleteLesson,
       _getLibrary = getLibrary,
       _auth = auth;

  final GetLessons _getLessons;
  final SyncLessons _syncLessons;
  final DeleteLesson _deleteLesson;
  final GetLibrary _getLibrary;
  final AuthService _auth;
  final StreamController<List<Lesson>> _lessonChanges =
      StreamController.broadcast();
  final StreamController<LibraryRoot> _libraryChanges =
      StreamController.broadcast();
  final StreamController<void> _resets = StreamController.broadcast();

  List<Lesson>? _lessons;
  LibraryRoot? _library;
  Future<List<Lesson>>? _loadingLessons;
  Future<LibraryRoot>? _loadingLibrary;

  /// `null` until the first load.
  List<Lesson>? get lessons => _lessons;

  /// `null` until the first load.
  LibraryRoot? get library => _library;

  Stream<List<Lesson>> get lessonChanges => _lessonChanges.stream;
  Stream<LibraryRoot> get libraryChanges => _libraryChanges.stream;

  /// Fires when the studied language changes: anything built on the old
  /// catalog (filters, selections) is stale.
  Stream<void> get resets => _resets.stream;

  /// Shows the cache and catches up with the server. Offline the cache is
  /// enough. Runs once; use [refreshLessons] to pull again.
  Future<List<Lesson>> loadLessons() =>
      _loadingLessons ??= _fetchLessons(tolerateOffline: true);

  /// Pull-to-refresh: unlike [loadLessons] a network failure is thrown.
  Future<List<Lesson>> refreshLessons() =>
      _loadingLessons = _fetchLessons(tolerateOffline: false);

  /// Re-reads the lessons from the cache without the server.
  Future<List<Lesson>> reloadLessonsFromCache() =>
      _loadingLessons = _readLessons();

  /// Offline the cached lessons are shown as a flat list.
  Future<LibraryRoot> loadLibrary() => _loadingLibrary ??= _fetchLibrary();

  Future<LibraryRoot> refreshLibrary() => _loadingLibrary = _fetchLibrary();

  /// Reloads both after lessons or folders were changed elsewhere.
  void reload() {
    _loadingLessons = _fetchLessons(tolerateOffline: true)..ignore();
    _loadingLibrary = _fetchLibrary()..ignore();
  }

  Future<void> deleteLesson(String id) async {
    await _deleteLesson(id);
    await reloadLessonsFromCache();
    refreshLibrary().ignore();
  }

  /// Call after the studied language changed and the old cache was wiped.
  void reset() {
    _lessons = null;
    _library = null;
    _resets.add(null);
    reload();
  }

  void dispose() {
    _lessonChanges.close();
    _libraryChanges.close();
    _resets.close();
  }

  Future<List<Lesson>> _fetchLessons({required bool tolerateOffline}) async {
    final language = _auth.session.user?.studiedLanguage ?? '';
    try {
      await _syncLessons(language: language);
    } on NetworkFailure {
      if (!tolerateOffline) rethrow;
    }
    return _readLessons();
  }

  Future<List<Lesson>> _readLessons() async {
    final lessons = await _getLessons();
    _lessons = lessons;
    _lessonChanges.add(lessons);
    return lessons;
  }

  Future<LibraryRoot> _fetchLibrary() async {
    LibraryRoot library;
    try {
      library = await _getLibrary();
    } on NetworkFailure {
      library = LibraryRoot(lessons: await _getLessons());
    }
    _library = library;
    _libraryChanges.add(library);
    return library;
  }
}
