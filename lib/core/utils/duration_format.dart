/// `m:ss.d` — компактная подпись позиции внутри аудио.
String formatPosition(int milliseconds) {
  final total = milliseconds < 0 ? 0 : milliseconds;
  final minutes = total ~/ 60000;
  final seconds = (total % 60000) ~/ 1000;
  final tenths = (total % 1000) ~/ 100;
  return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
}

/// `m:ss` — длительность без долей секунды (подпись в списке уроков).
String formatClock(int milliseconds) {
  final total = milliseconds < 0 ? 0 : milliseconds;
  final minutes = total ~/ 60000;
  final seconds = (total % 60000) ~/ 1000;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// `dd.MM.yyyy` в локальной зоне пользователя.
String formatDate(DateTime utc) {
  final local = utc.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}
