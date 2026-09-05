/// Base application failure used by the domain and presentation layers.
abstract class Failure implements Exception {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Local storage failure: database or files.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Audio file failure: copying, reading duration, building the waveform.
class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.cause});
}

/// Invalid user input or a broken domain invariant.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// The requested entity does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}

/// The server did not answer: no network, timeout, dropped connection.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}
