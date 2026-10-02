import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/bootstrap/app_bootstrap.dart';
import 'package:shado/core/bootstrap/reconnect_sync.dart';
import 'package:shado/core/router/app_router.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';

final appBootstrapProvider = Provider<AppBootstrap>((ref) {
  final bootstrap = AppBootstrap(
    auth: ref.watch(authServiceProvider),
    progressSummary: ref.watch(progressSummaryServiceProvider),
  );
  ref.onDispose(bootstrap.dispose);
  return bootstrap;
});

/// Syncs lessons and progress once the connection is back.
final reconnectSyncProvider = Provider<ReconnectSync>((ref) {
  final sync = ReconnectSync(
    network: ref.watch(networkStatusProvider),
    auth: ref.watch(authServiceProvider),
    catalog: ref.watch(lessonCatalogServiceProvider),
    reporter: ref.watch(progressReporterProvider),
    progressSummary: ref.watch(progressSummaryServiceProvider),
  );
  ref.onDispose(sync.dispose);
  return sync;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(ref.watch(appBootstrapProvider));
  ref.onDispose(router.dispose);
  return router;
});
