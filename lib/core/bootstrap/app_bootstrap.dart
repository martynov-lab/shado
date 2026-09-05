import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/progress/presentation/controllers/progress_providers.dart';

/// Warms up data for the first frame after sign-in; the router keeps the
/// splash while it runs.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final status = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (status != AuthStatus.authenticated) return;

  try {
    // The timeout guards against a dead network.
    await ref
        .read(progressSummaryProvider.future)
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    // The summary provider keeps the error; the splash does not wait for it.
  }
});
