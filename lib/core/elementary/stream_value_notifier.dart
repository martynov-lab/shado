import 'dart:async';

import 'package:flutter/foundation.dart';

/// Holds the latest value of a service stream so a model can hand it to its
/// widget model. Starts from [initial]; call [dispose] to stop listening.
class StreamValueNotifier<T> extends ValueNotifier<T> {
  StreamValueNotifier(super.initial, Stream<T> stream) {
    _subscription = stream.listen((value) => this.value = value);
  }

  late final StreamSubscription<T> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
