import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_monitor.dart';

/// [NetworkMonitor] on top of the platform connectivity status.
class ConnectivityNetworkMonitor implements NetworkMonitor {
  ConnectivityNetworkMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
