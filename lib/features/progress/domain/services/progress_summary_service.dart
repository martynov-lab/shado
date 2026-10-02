import 'dart:async';

import '../entities/progress_summary.dart';
import '../repositories/progress_repository.dart';

/// Progress summary shared by the home and progress screens. The reporter
/// pushes a fresh one after every upload.
class ProgressSummaryService {
  ProgressSummaryService(this._repository);

  final ProgressRepository _repository;
  final StreamController<ProgressSummary> _changes =
      StreamController.broadcast();

  ProgressSummary? _summary;
  Future<ProgressSummary>? _loading;

  /// `null` until the first successful load.
  ProgressSummary? get summary => _summary;

  Stream<ProgressSummary> get changes => _changes.stream;

  /// Loads the summary once and keeps the result, including a failure.
  /// Use [refresh] to try again.
  Future<ProgressSummary> load() => _loading ??= _fetch();

  Future<ProgressSummary> refresh() => _loading = _fetch();

  void accept(ProgressSummary summary) {
    _summary = summary;
    _changes.add(summary);
  }

  void dispose() => _changes.close();

  Future<ProgressSummary> _fetch() async {
    final summary = await _repository.getSummary();
    accept(summary);
    return summary;
  }
}
