import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/core/network/network_status.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/di/folder_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/domain/services/auth_service.dart';
import '../../../../languages/domain/entities/language.dart';
import '../../../../languages/domain/services/language_service.dart';
import '../../../../progress/domain/usecases/get_lesson_progress.dart';
import '../../../domain/entities/folder.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/lesson_download.dart';
import '../../../domain/entities/library_root.dart';
import '../../../domain/lesson_visibility.dart';
import '../../../domain/services/lesson_catalog_service.dart';
import '../../../domain/services/lesson_download_service.dart';
import '../../../domain/usecases/create_folder.dart';
import '../../../domain/usecases/get_topics.dart';

/// Data and actions of the lessons screen: the library root, the whole
/// catalog for search, and what the filters need.
class LessonsModel extends ElementaryModel {
  LessonsModel(ProviderContainer container)
    : _catalog = container.read(lessonCatalogServiceProvider),
      _auth = container.read(authServiceProvider),
      _languages = container.read(languageServiceProvider),
      _getTopics = container.read(getTopicsProvider),
      _createFolder = container.read(createFolderProvider),
      _getLessonProgress = container.read(getLessonProgressProvider),
      _downloadService = container.read(lessonDownloadServiceProvider),
      _network = container.read(networkStatusProvider);

  final LessonCatalogService _catalog;
  final AuthService _auth;
  final LanguageService _languages;
  final GetTopics _getTopics;
  final CreateFolder _createFolder;
  final GetLessonProgress _getLessonProgress;
  final LessonDownloadService _downloadService;
  final NetworkStatus _network;

  late final ValueNotifier<AsyncState<LibraryRoot>> _library = ValueNotifier(
    switch (_catalog.library) {
      final library? => AsyncReady(library),
      null => const AsyncPending(),
    },
  );
  late final StreamValueNotifier<List<Lesson>> _lessons = StreamValueNotifier(
    _catalog.lessons ?? const [],
    _catalog.lessonChanges,
  );
  late final StreamValueNotifier<UserRole?> _role = StreamValueNotifier(
    _auth.session.user?.role,
    _auth.changes.map((session) => session.user?.role),
  );
  late final StreamValueNotifier<List<Accent>> _accents = StreamValueNotifier(
    _languages.currentAccents,
    _languages.currentChanges.map((language) => language?.accents ?? const []),
  );
  late final StreamValueNotifier<Map<String, LessonDownload>> _downloads =
      StreamValueNotifier(_downloadService.downloads, _downloadService.changes);
  late final StreamValueNotifier<bool> _isOnline = StreamValueNotifier(
    _network.isOnline,
    _network.changes,
  );
  StreamSubscription<LibraryRoot>? _librarySubscription;
  bool _isDisposed = false;

  ValueListenable<AsyncState<LibraryRoot>> get library => _library;

  /// Every lesson of the studied language; search looks through all of them.
  ValueListenable<List<Lesson>> get lessons => _lessons;

  ValueListenable<UserRole?> get role => _role;

  /// Accents of the studied language for the accent filter.
  ValueListenable<List<Accent>> get accents => _accents;

  /// Downloaded and downloading lessons by id.
  ValueListenable<Map<String, LessonDownload>> get downloads => _downloads;

  ValueListenable<bool> get isOnline => _isOnline;

  /// Fires after the studied language changed.
  Stream<void> get catalogResets => _catalog.resets;

  @override
  void init() {
    super.init();
    _librarySubscription = _catalog.libraryChanges.listen(
      (library) => _library.value = AsyncReady(library),
    );
    unawaited(_track(_catalog.loadLibrary()));
    _catalog.loadLessons().ignore();
    _languages.loadForCurrent();
    _downloadService.load().ignore();
  }

  Future<void> retryLibrary() {
    _library.value = const AsyncPending();
    return _track(_catalog.refreshLibrary());
  }

  /// Re-reads the root and catches the catalog up with the server. If the
  /// catalog can't be refreshed, the cached lessons stay.
  Future<void> refresh() async {
    await Future.wait([
      _track(_catalog.refreshLibrary()),
      _refreshLessonsQuietly(),
    ]);
  }

  Future<void> _refreshLessonsQuietly() async {
    try {
      await _catalog.refreshLessons();
    } on Object catch (_) {
      // The cached lessons stay.
    }
  }

  Future<List<Topic>> loadTopics() => _getTopics();

  Future<double> lessonProgress(Lesson lesson) => _getLessonProgress(
    lessonId: lesson.id,
    segmentCount: lesson.segmentCount,
  );

  Future<void> deleteLesson(String id) => _catalog.deleteLesson(id);

  /// Downloads the lesson, or removes the download of a downloaded one.
  Future<void> toggleDownload(String id) =>
      switch (_downloadService.stateOf(id)) {
        NotDownloaded() => _downloadService.download(id),
        Downloaded() => _downloadService.remove(id),
        Downloading() => Future.value(),
      };

  /// Creates a folder in the root; the role decides whether it is public.
  Future<Folder> createFolder(String title) async {
    final folder = await _createFolder(
      title: title,
      isPublic: publicFlagForRole(_role.value, requested: true),
    );
    await _catalog.refreshLibrary();
    return folder;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _librarySubscription?.cancel();
    _library.dispose();
    _lessons.dispose();
    _role.dispose();
    _accents.dispose();
    _downloads.dispose();
    _isOnline.dispose();
    super.dispose();
  }

  Future<void> _track(Future<LibraryRoot> request) async {
    final result = await AsyncState.guard(() => request);
    if (!_isDisposed) _library.value = result;
  }
}
