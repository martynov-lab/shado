import 'entities/progress_summary.dart';

/// Раскладывает присланную сервером неделю в ровно 7 подряд идущих дней,
/// оканчивающихся сегодняшним ([today] в формате `YYYY-MM-DD`).
///
/// Сервер опускает дни без активности, поэтому график и «Эта неделя» рисовали
/// только дни с занятиями. Здесь недостающие дни возвращаются нулевыми — столбец
/// пустой, но подпись дня недели на месте. Если [today] не распознан (сводки ещё
/// нет), окно строится от сегодняшней локальной даты.
List<ProgressDay> weekWithGaps(List<ProgressDay> week, String today) {
  final anchor = _parseDay(today) ?? _todayUtc();
  final byDay = {
    for (final day in week)
      if (_parseDay(day.day) case final date?) _format(date): day,
  };
  return [
    for (var back = 6; back >= 0; back--)
      _dayFor(byDay, anchor.subtract(Duration(days: back))),
  ];
}

ProgressDay _dayFor(Map<String, ProgressDay> byDay, DateTime date) {
  final key = _format(date);
  return byDay[key] ?? ProgressDay(day: key, listenedMs: 0, segmentRepeats: 0);
}

/// Дата без времени в UTC — арифметика по дням тогда не зависит от перевода
/// часов, а сервер и так считает дни в UTC.
DateTime? _parseDay(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

DateTime _todayUtc() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day);
}

String _format(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
