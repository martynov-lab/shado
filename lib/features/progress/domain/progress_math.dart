// Чистая логика прогресса урока по локальным счётчикам повторов.

/// Урок пройден, когда каждый сегмент повторён не меньше [target] раз.
///
/// [reps] — `segmentIndex → количество повторов`; отсутствующий индекс = 0.
bool progressIsComplete(Map<int, int> reps, int segmentCount, int target) {
  if (segmentCount <= 0 || target <= 0) return false;
  for (var i = 0; i < segmentCount; i++) {
    if ((reps[i] ?? 0) < target) return false;
  }
  return true;
}

/// Доля пройденности `0..1` для прогресс-бара карточки: усреднённая
/// готовность сегментов (каждый вносит не больше [target]).
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
