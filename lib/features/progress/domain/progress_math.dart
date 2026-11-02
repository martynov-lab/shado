// Lesson progress math based on star ratings.

import 'entities/item_rating.dart';

/// Whether the lesson is done: every item rated with the top score.
bool progressIsComplete(Map<String, int> stars, List<String> itemKeys) {
  if (itemKeys.isEmpty) return false;
  return itemKeys.every((key) => (stars[key] ?? 0) >= kMaxStars);
}

/// Completion share `0..1` — the average rating over the top score; an
/// unrated item counts as zero.
double lessonProgressFraction(Map<String, int> stars, List<String> itemKeys) {
  if (itemKeys.isEmpty) return 0;
  var total = 0;
  for (final key in itemKeys) {
    total += (stars[key] ?? 0).clamp(0, kMaxStars);
  }
  return (total / (itemKeys.length * kMaxStars)).clamp(0, 1).toDouble();
}
