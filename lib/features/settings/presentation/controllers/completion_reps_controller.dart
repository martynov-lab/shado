import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';

/// Completion threshold editing; the state is a saving flag.
class CompletionRepsController extends Notifier<bool> {
  static const int minReps = 1;
  static const int maxReps = 1000;

  @override
  bool build() => false;

  /// Saves the threshold; `null` means success, otherwise an error text.
  Future<String?> save(int reps) async {
    if (state) return null;
    if (reps < minReps || reps > maxReps) {
      return 'Порог — от $minReps до $maxReps';
    }
    state = true;
    try {
      await ref.read(settingsRemoteDataSourceProvider).setCompletionReps(reps);
      ref.invalidate(completionRepsProvider);
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return 'Не удалось сохранить: $error';
    } finally {
      state = false;
    }
  }
}

/// `true` while the threshold is being saved.
final completionRepsControllerProvider =
    NotifierProvider<CompletionRepsController, bool>(
      CompletionRepsController.new,
    );
