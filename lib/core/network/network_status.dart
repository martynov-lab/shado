import 'dart:async';

import 'network_monitor.dart';

/// Whether the device is online right now, shared by the screens.
class NetworkStatus {
  NetworkStatus(this._monitor) {
    _subscription = _monitor.onlineChanges.listen(_apply);
    unawaited(_readInitial());
  }

  final NetworkMonitor _monitor;
  final StreamController<bool> _changes = StreamController.broadcast();
  late final StreamSubscription<bool> _subscription;

  bool _isOnline = true;

  /// `true` until the platform reports otherwise.
  bool get isOnline => _isOnline;

  /// Fires on every change of [isOnline].
  Stream<bool> get changes => _changes.stream;

  void dispose() {
    _subscription.cancel();
    _changes.close();
  }

  Future<void> _readInitial() async {
    try {
      _apply(await _monitor.isOnline());
    } catch (_) {
      // Without a platform answer the app counts as online.
    }
  }

  void _apply(bool online) {
    if (online == _isOnline || _changes.isClosed) return;
    _isOnline = online;
    _changes.add(online);
  }
}
