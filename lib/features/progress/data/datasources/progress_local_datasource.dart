/// Неотправленная дневная дельта активности.
class PendingEvents {
  const PendingEvents({required this.listenedMs, required this.segmentRepeats});

  static const PendingEvents empty = PendingEvents(
    listenedMs: 0,
    segmentRepeats: 0,
  );

  final int listenedMs;
  final int segmentRepeats;

  /// Нечего слать — не дёргаем сеть.
  bool get isEmpty => listenedMs <= 0 && segmentRepeats <= 0;
}

/// Локальные счётчики прогресса. Живут в отдельной БД: минуты и повторы терять
/// нельзя, поэтому миграции здесь только аддитивные (в отличие от кеша уроков).
abstract interface class ProgressLocalDataSource {
  /// +1 повтор сегмента: и в счётчик по сегменту (для «пройдено» и прогресс-бара
  /// карточки), и в неотправленную дневную дельту.
  Future<void> bumpSegment(String lessonId, int segmentIndex);

  /// Копит прослушанные миллисекунды в неотправленной дельте.
  Future<void> addListened(int ms);

  /// Повторы по сегментам урока: `segmentIndex → reps`.
  Future<Map<int, int>> readReps(String lessonId);

  Future<PendingEvents> readPending();

  /// Вычитает уже отправленное (а не обнуляет) — активность, накопившаяся во
  /// время запроса, не теряется.
  Future<void> subtractPending(int listenedMs, int segmentRepeats);

  Future<bool> isCompletedSent(String lessonId);

  Future<void> markCompletedSent(String lessonId);

  /// Стирает весь прогресс: выход из аккаунта.
  Future<void> clear();
}
