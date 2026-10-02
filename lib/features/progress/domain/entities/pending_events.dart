/// Pending daily activity delta.
class PendingEvents {
  const PendingEvents({required this.listenedMs, required this.segmentRepeats});

  static const PendingEvents empty = PendingEvents(
    listenedMs: 0,
    segmentRepeats: 0,
  );

  final int listenedMs;
  final int segmentRepeats;

  /// Nothing to send — skip the network call.
  bool get isEmpty => listenedMs <= 0 && segmentRepeats <= 0;
}
