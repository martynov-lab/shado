/// Whether the device has a network connection.
abstract interface class NetworkMonitor {
  /// Fires `true` when the connection appears and `false` when it is lost.
  Stream<bool> get onlineChanges;

  Future<bool> isOnline();
}
