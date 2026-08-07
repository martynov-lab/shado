import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../data/datasources/progress_local_datasource.dart';
import '../../data/datasources/progress_local_datasource_sqflite.dart';
import '../../data/datasources/progress_remote_datasource.dart';
import '../../data/progress_reporter.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/progress_math.dart';

final progressLocalDataSourceProvider = Provider<ProgressLocalDataSource>(
  (ref) => SqfliteProgressLocalDataSource(),
);

final progressRemoteDataSourceProvider = Provider<ProgressRemoteDataSource>(
  (ref) => ApiProgressRemoteDataSource(ref.watch(apiClientProvider)),
);

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>(
  (ref) => ApiSettingsRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Порог пройденности (`lesson_completion_reps`). Кешируем: читают все экраны.
final completionRepsProvider = FutureProvider<int>(
  (ref) => ref.watch(settingsRemoteDataSourceProvider).getCompletionReps(),
);

/// Движок отчётности на всё приложение. После успешного события кладёт свежую
/// сводку в [progressSummaryProvider].
final progressReporterProvider = Provider<ProgressReporter>((ref) {
  return ProgressReporter(
    local: ref.watch(progressLocalDataSourceProvider),
    remote: ref.watch(progressRemoteDataSourceProvider),
    onSummary: (summary) =>
        ref.read(progressSummaryProvider.notifier).acceptServer(summary),
  );
});

/// Сводка прогресса. Наполняется `GET /v1/progress` при входе и свежими
/// ответами событий из [ProgressReporter].
class ProgressSummaryController extends AsyncNotifier<ProgressSummary> {
  @override
  Future<ProgressSummary> build() =>
      ref.watch(progressRemoteDataSourceProvider).getSummary();

  /// Свежая сводка из ответа события — без лишнего запроса.
  void acceptServer(ProgressSummary summary) =>
      state = AsyncValue.data(summary);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(progressRemoteDataSourceProvider).getSummary(),
    );
  }
}

final progressSummaryProvider =
    AsyncNotifierProvider<ProgressSummaryController, ProgressSummary>(
      ProgressSummaryController.new,
    );

/// История активности за окно дней — для тепловой карты и серии.
final progressHistoryProvider = FutureProvider.autoDispose<List<ProgressDay>>(
  (ref) => ref.watch(progressRemoteDataSourceProvider).getHistory(days: 70),
);

/// Доля пройденности урока `0..1` для прогресс-бара карточки: локальные повторы
/// против порога. Пересчитывается при повторном входе в список (autoDispose).
final lessonProgressProvider = FutureProvider.autoDispose
    .family<double, ({String lessonId, int segmentCount})>((ref, key) async {
      final reps = await ref
          .watch(progressLocalDataSourceProvider)
          .readReps(key.lessonId);
      final target = await ref.watch(completionRepsProvider.future);
      return lessonProgressFraction(reps, key.segmentCount, target);
    });
