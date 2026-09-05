/// Source audio range used by the lesson; trimming never edits the file.
class AudioTrim {
  const AudioTrim({required this.startMs, required this.endMs});

  /// The whole file — nothing is trimmed.
  const AudioTrim.full(int durationMs) : startMs = 0, endMs = durationMs;

  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;

  bool get isEmpty => durationMs <= 0;

  /// Whether anything is trimmed off a file of [fileDurationMs].
  bool isTrimmedFrom(int fileDurationMs) =>
      startMs > 0 || endMs < fileDurationMs;

  int clampMs(int ms) => ms.clamp(startMs, endMs);

  /// Clamps the range to the file bounds.
  AudioTrim clampedTo(int fileDurationMs) {
    if (fileDurationMs <= 0) return this;
    final start = startMs.clamp(0, fileDurationMs);
    final end = endMs.clamp(start, fileDurationMs);
    // A collapsed range falls back to the whole file.
    if (end <= start) return AudioTrim.full(fileDurationMs);
    return AudioTrim(startMs: start, endMs: end);
  }

  @override
  bool operator ==(Object other) =>
      other is AudioTrim && other.startMs == startMs && other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);

  @override
  String toString() => 'AudioTrim($startMs..$endMs)';
}
