// Lesson progress math based on local repeat counters.

/// Whether the lesson is done: every segment repeated at least [target] times.
bool progressIsComplete(Map<int, int> reps, int segmentCount, int target) {
  if (segmentCount <= 0 || target <= 0) return false;
  for (var i = 0; i < segmentCount; i++) {
    if ((reps[i] ?? 0) < target) return false;
  }
  return true;
}

/// Completion share `0..1` — the averaged readiness of the segments.
double lessonProgressFraction(
  Map<int, int> reps,
  int segmentCount,
  int target,
) {
  if (segmentCount <= 0 || target <= 0) return 0;
  var done = 0;
  for (var i = 0; i < segmentCount; i++) {
    final r = reps[i] ?? 0;
    done += r < target ? r : target;
  }
  final fraction = done / (segmentCount * target);
  return fraction.clamp(0, 1).toDouble();
}
