import 'entities/progress_summary.dart';

// Серия занятий: подряд идущие активные дни, оканчивающиеся последним активным.

bool _isActive(ProgressDay day) => day.listenedMs > 0 || day.segmentRepeats > 0;

DateTime? _parseDay(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Текущая серия: сколько активных дней подряд, начиная с самого свежего
/// активного дня в [history]. Разрыв в календаре обрывает серию.
int currentStreak(List<ProgressDay> history) {
  final active = <DateTime>{};
  for (final day in history) {
    if (!_isActive(day)) continue;
    final date = _parseDay(day.day);
    if (date != null) active.add(date);
  }
  if (active.isEmpty) return 0;

  final sorted = active.toList()..sort((a, b) => b.compareTo(a));
  var streak = 1;
  for (var i = 1; i < sorted.length; i++) {
    final expected = sorted[i - 1].subtract(const Duration(days: 1));
    if (sorted[i] == expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
