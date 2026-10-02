import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/core_providers.dart';
import 'package:shado/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:shado/features/settings/data/repositories/playback_settings_repository_impl.dart';
import 'package:shado/features/settings/data/repositories/server_settings_repository_impl.dart';
import 'package:shado/features/settings/domain/repositories/playback_settings_repository.dart';
import 'package:shado/features/settings/domain/repositories/server_settings_repository.dart';
import 'package:shado/features/settings/domain/services/completion_threshold_service.dart';
import 'package:shado/features/settings/domain/services/playback_settings_service.dart';

final playbackSettingsRepositoryProvider = Provider<PlaybackSettingsRepository>(
  (ref) => PlaybackSettingsRepositoryImpl(),
);

final playbackSettingsServiceProvider = Provider<PlaybackSettingsService>((
  ref,
) {
  final service = PlaybackSettingsService(
    ref.watch(playbackSettingsRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>(
  (ref) => ApiSettingsRemoteDataSource(ref.watch(apiClientProvider)),
);

final serverSettingsRepositoryProvider = Provider<ServerSettingsRepository>(
  (ref) => ServerSettingsRepositoryImpl(
    ref.watch(settingsRemoteDataSourceProvider),
  ),
);

final completionThresholdServiceProvider = Provider<CompletionThresholdService>(
  (ref) {
    final service = CompletionThresholdService(
      ref.watch(serverSettingsRepositoryProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);
