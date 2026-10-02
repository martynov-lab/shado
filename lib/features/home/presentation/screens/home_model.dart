import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';

import '../../../auth/domain/services/auth_service.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/domain/services/lesson_catalog_service.dart';
import '../../../progress/domain/entities/progress_summary.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../../../progress/domain/services/progress_summary_service.dart';
import '../../../progress/domain/usecases/get_lesson_progress.dart';

/// Data of the home screen: the user's email, progress, history and the
/// lesson catalog.
class HomeModel extends ElementaryModel {
  HomeModel(ProviderContainer container)
    : _summaryService = container.read(progressSummaryServiceProvider),
      _repository = container.read(progressRepositoryProvider),
      _getLessonProgress = container.read(getLessonProgressProvider),
      _auth = container.read(authServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider);

  final ProgressSummaryService _summaryService;
  final ProgressRepository _repository;
  final GetLessonProgress _getLessonProgress;
  final AuthService _auth;

  late final StreamValueNotifier<String> _email = StreamValueNotifier(
    _auth.session.user?.email ?? '',
    _auth.changes.map((session) => session.user?.email ?? ''),
  );
  final LessonCatalogService _catalog;

  late final StreamValueNotifier<List<Lesson>> _lessons = StreamValueNotifier(
    _catalog.lessons ?? const [],
    _catalog.lessonChanges,
  );

  late final ValueNotifier<ProgressSummary?> _summary = ValueNotifier(
    _summaryService.summary,
  );
  final ValueNotifier<List<ProgressDay>> _history = ValueNotifier(const []);
  StreamSubscription<ProgressSummary>? _summarySubscription;
  bool _isDisposed = false;

  /// `null` while loading or after a failure: the screen shows zeros then.
  ValueListenable<ProgressSummary?> get summary => _summary;

  /// Stays empty if the history fails to load.
  ValueListenable<List<ProgressDay>> get history => _history;

  ValueListenable<String> get email => _email;
  ValueListenable<List<Lesson>> get lessons => _lessons;

  @override
  void init() {
    super.init();
    _summarySubscription = _summaryService.changes.listen(
      (summary) => _summary.value = summary,
    );
    _summaryService.load().ignore();
    unawaited(_loadHistory());
    _catalog.loadLessons().ignore();
  }

  Future<double> lessonProgress(String lessonId, int segmentCount) =>
      _getLessonProgress(lessonId: lessonId, segmentCount: segmentCount);

  @override
  void dispose() {
    _isDisposed = true;
    _summarySubscription?.cancel();
    _summary.dispose();
    _history.dispose();
    _email.dispose();
    _lessons.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _repository.getHistory(days: 70);
      if (!_isDisposed) _history.value = history;
    } catch (_) {
      return;
    }
  }
}
