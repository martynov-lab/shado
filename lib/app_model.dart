import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/di/app_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/theme/theme.dart';

/// What the app root needs: the router, the theme choice, the progress
/// reporter and the sync after a reconnect.
class AppModel extends ElementaryModel {
  AppModel(ProviderContainer container)
    : router = container.read(appRouterProvider),
      _theme = container.read(themeControllerProvider),
      _reporter = container.read(progressReporterProvider) {
    // Starts the sync after reconnects for the app lifetime.
    container.read(reconnectSyncProvider);
  }

  final GoRouter router;
  final ThemeController _theme;
  final ProgressReporter _reporter;

  ValueListenable<ThemeMode> get themeMode => _theme;

  /// Sends the activity collected on the device to the server.
  Future<void> flushProgress() => _reporter.flush();
}
