import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/core_providers.dart';
import 'package:shado/di/settings_providers.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource_sqflite.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:shado/features/progress/domain/repositories/progress_repository.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';
import 'package:shado/features/progress/domain/usecases/get_lesson_progress.dart';

final progressLocalDataSourceProvider = Provider<ProgressLocalDataSource>(
  (ref) => SqfliteProgressLocalDataSource(),
);

final progressRemoteDataSourceProvider = Provider<ProgressRemoteDataSource>(
  (ref) => ApiProgressRemoteDataSource(ref.watch(apiClientProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(
    local: ref.watch(progressLocalDataSourceProvider),
    remote: ref.watch(progressRemoteDataSourceProvider),
  ),
);

final progressSummaryServiceProvider = Provider<ProgressSummaryService>((ref) {
  final service = ProgressSummaryService(ref.watch(progressRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});

final progressReporterProvider = Provider<ProgressReporter>(
  (ref) => ProgressReporter(
    repository: ref.watch(progressRepositoryProvider),
    summary: ref.watch(progressSummaryServiceProvider),
  ),
);

final getLessonProgressProvider = Provider<GetLessonProgress>(
  (ref) => GetLessonProgress(
    ref.watch(progressRepositoryProvider),
    ref.watch(completionThresholdServiceProvider),
  ),
);
