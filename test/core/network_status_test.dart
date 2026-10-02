import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/core/network/network_status.dart';

/// Platform connectivity driven by the test.
class _FakeNetworkMonitor implements NetworkMonitor {
  _FakeNetworkMonitor(this.initial);

  /// What `isOnline` answers; an error stands for a missing platform.
  final Future<bool> Function() initial;
  final StreamController<bool> changes = StreamController.broadcast();

  @override
  Stream<bool> get onlineChanges => changes.stream;

  @override
  Future<bool> isOnline() => initial();
}

void main() {
  group('$NetworkStatus', () {
    test('takes the platform status at start', () async {
      final status = _makeStatus(_FakeNetworkMonitor(() async => false));

      await pumpEventQueue();

      expect(status.isOnline, isFalse);
    });

    test('reports each change once', () async {
      final monitor = _FakeNetworkMonitor(() async => true);
      final status = _makeStatus(monitor);
      final events = <bool>[];
      status.changes.listen(events.add);
      await pumpEventQueue();

      monitor.changes
        ..add(false)
        ..add(false)
        ..add(true);
      await pumpEventQueue();

      expect(events, equals([false, true]));
    });

    test('stays online when the platform does not answer', () async {
      final status = _makeStatus(
        _FakeNetworkMonitor(() async => throw StateError('no plugin')),
      );

      await pumpEventQueue();

      expect(status.isOnline, isTrue);
    });
  });
}

NetworkStatus _makeStatus(_FakeNetworkMonitor monitor) {
  final status = NetworkStatus(monitor);
  addTearDown(() {
    status.dispose();
    return monitor.changes.close();
  });
  return status;
}
