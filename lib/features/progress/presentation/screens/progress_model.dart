import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/domain/services/lesson_catalog_service.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/progress_summary_service.dart';

/// Data of the progress screen: the summary, the activity history and the
/// lesson catalog for the continue block.
class ProgressModel extends ElementaryModel {
  ProgressModel(ProviderContainer container)
    : _summaryService = container.read(progressSummaryServiceProvider),
      _repository = container.read(progressRepositoryProvider),
      _catalog = container.read(lessonCatalogServiceProvider);

  final ProgressSummaryService _summaryService;
  final ProgressRepository _repository;
  final LessonCatalogService _catalog;

  late final StreamValueNotifier<List<Lesson>> _lessons = StreamValueNotifier(
    _catalog.lessons ?? const [],
    _catalog.lessonChanges,
  );

  late final ValueNotifier<AsyncState<ProgressSummary>> _summary =
      ValueNotifier(switch (_summaryService.summary) {
        final summary? => AsyncReady(summary),
        null => const AsyncPending(),
      });
  final ValueNotifier<List<ProgressDay>> _history = ValueNotifier(const []);
  StreamSubscription<ProgressSummary>? _summarySubscription;
  bool _isDisposed = false;

  ValueListenable<AsyncState<ProgressSummary>> get summary => _summary;

  /// Stays empty if the history fails to load: the screen works without it.
  ValueListenable<List<ProgressDay>> get history => _history;

  ValueListenable<List<Lesson>> get lessons => _lessons;

  @override
  void init() {
    super.init();
    _summarySubscription = _summaryService.changes.listen(
      (summary) => _summary.value = AsyncReady(summary),
    );
    unawaited(_track(_summaryService.load()));
    unawaited(_loadHistory());
    _catalog.loadLessons().ignore();
  }

  Future<void> refreshSummary() {
    _summary.value = const AsyncPending();
    return _track(_summaryService.refresh());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _summarySubscription?.cancel();
    _summary.dispose();
    _history.dispose();
    _lessons.dispose();
    super.dispose();
  }

  Future<void> _track(Future<ProgressSummary> request) async {
    final result = await AsyncState.guard(() => request);
    if (!_isDisposed) _summary.value = result;
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
