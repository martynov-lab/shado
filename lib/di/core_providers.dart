import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/audio/shadowing_audio_handler.dart';
import 'package:shado/core/network/api_client.dart';
import 'package:shado/core/network/connectivity_network_monitor.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/core/network/network_status.dart';
import 'package:shado/core/storage/token_storage.dart';
import 'package:shado/theme/theme.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final networkMonitorProvider = Provider<NetworkMonitor>(
  (ref) => ConnectivityNetworkMonitor(),
);

final networkStatusProvider = Provider<NetworkStatus>((ref) {
  final status = NetworkStatus(ref.watch(networkMonitorProvider));
  ref.onDispose(status.dispose);
  return status;
});

/// One API client for the whole app, with a shared `Dio` and interceptor.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokens: ref.watch(tokenStorageProvider)),
);

/// Media session handler. `main()` overrides it on platforms that have one;
/// elsewhere (desktop, tests) it stays `null`.
final audioHandlerProvider = Provider<ShadowingAudioHandler?>((ref) => null);

/// `main()` overrides it with an instance that has already read the saved
/// theme.
final themeControllerProvider = Provider<ThemeController>((ref) {
  final controller = ThemeController();
  unawaited(controller.restore());
  ref.onDispose(controller.dispose);
  return controller;
});
