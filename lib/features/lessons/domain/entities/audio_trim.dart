/// Отрезок исходного аудио, попавший в урок: всё, что вне него, обрезано.
///
/// Обрезка не трогает файл — он остаётся целым, а урок живёт внутри
/// `startMs..endMs`. Куски размечаются в тех же абсолютных миллисекундах файла,
/// поэтому обрезка головы не сдвигает уже расставленные метки, а саму обрезку
/// всегда можно раздвинуть обратно.
class AudioTrim {
  const AudioTrim({required this.startMs, required this.endMs});

  /// Файл целиком — обрезки нет.
  const AudioTrim.full(int durationMs) : startMs = 0, endMs = durationMs;

  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;

  bool get isEmpty => durationMs <= 0;

  /// Отрезану ли хоть что-то у файла длиной [fileDurationMs].
  bool isTrimmedFrom(int fileDurationMs) =>
      startMs > 0 || endMs < fileDurationMs;

  int clampMs(int ms) => ms.clamp(startMs, endMs);

  /// Вписывает отрезок в границы файла: разметка с экрана создания приходит
  /// раньше, чем репозиторий узнаёт настоящую длительность.
  AudioTrim clampedTo(int fileDurationMs) {
    if (fileDurationMs <= 0) return this;
    final start = startMs.clamp(0, fileDurationMs);
    final end = endMs.clamp(start, fileDurationMs);
    // Схлопнувшийся отрезок бессмыслен — берём файл целиком.
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
