import 'dart:async';

import '../../../../core/error/failures.dart';
import '../repositories/server_settings_repository.dart';

/// How many repeats of every segment mark a lesson as done. Read by the
/// lesson, progress and admin screens; only the owner changes it.
class CompletionThresholdService {
  CompletionThresholdService(this._repository);

  static const int minReps = 1;
  static const int maxReps = 1000;

  final ServerSettingsRepository _repository;
  final StreamController<int> _changes = StreamController.broadcast();

  int? _reps;
  Future<int>? _loading;

  /// `null` until the first successful load.
  int? get reps => _reps;

  Stream<int> get changes => _changes.stream;

  /// Loads the threshold once and keeps the result, including a failure.
  Future<int> load() => _loading ??= _fetch();

  /// Throws [ValidationFailure] for a value outside [minReps]..[maxReps].
  Future<void> save(int reps) async {
    if (reps < minReps || reps > maxReps) {
      throw const ValidationFailure(
        'Threshold must be from $minReps to $maxReps',
      );
    }
    _apply(await _repository.setCompletionReps(reps));
  }

  void dispose() => _changes.close();

  Future<int> _fetch() async {
    final reps = await _repository.getCompletionReps();
    _apply(reps);
    return reps;
  }

  void _apply(int reps) {
    _reps = reps;
    _changes.add(reps);
  }
}
