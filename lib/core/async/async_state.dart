/// Result of a load the screen shows: still going, done, or failed.
sealed class AsyncState<T> {
  const AsyncState();

  /// Runs [load] and wraps its result or error.
  static Future<AsyncState<T>> guard<T>(Future<T> Function() load) async {
    try {
      return AsyncReady(await load());
    } catch (error, stackTrace) {
      return AsyncFailed(error, stackTrace);
    }
  }

  /// `null` until the load succeeds.
  T? get value => switch (this) {
    AsyncReady(:final value) => value,
    _ => null,
  };

  /// Transforms the loaded value; pending and failed states pass through.
  AsyncState<R> mapValue<R>(R Function(T value) transform) => switch (this) {
    AsyncReady(:final value) => AsyncReady(transform(value)),
    AsyncPending() => AsyncPending<R>(),
    AsyncFailed(:final error, :final stackTrace) => AsyncFailed<R>(
      error,
      stackTrace,
    ),
  };
}

final class AsyncPending<T> extends AsyncState<T> {
  const AsyncPending();
}

final class AsyncReady<T> extends AsyncState<T> {
  const AsyncReady(this.value);

  @override
  final T value;
}

final class AsyncFailed<T> extends AsyncState<T> {
  const AsyncFailed(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
