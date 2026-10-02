import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/bootstrap/app_bootstrap.dart';
import 'package:shado/core/router/app_router.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/progress_providers.dart';

final appBootstrapProvider = Provider<AppBootstrap>((ref) {
  final bootstrap = AppBootstrap(
    auth: ref.watch(authServiceProvider),
    progressSummary: ref.watch(progressSummaryServiceProvider),
  );
  ref.onDispose(bootstrap.dispose);
  return bootstrap;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(ref.watch(appBootstrapProvider));
  ref.onDispose(router.dispose);
  return router;
});
