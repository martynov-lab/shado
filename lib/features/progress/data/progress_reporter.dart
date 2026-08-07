import '../domain/entities/progress_summary.dart';
import '../domain/progress_math.dart';
import 'datasources/progress_local_datasource.dart';
import 'datasources/progress_remote_datasource.dart';

/// Движок отчётности прогресса: копит активность локально и батчит её на сервер.
///
/// Ошибки сети/сервера глотаем — накопленная дельта остаётся в [local] и уйдёт
/// следующим [flush]. Периодичность задаёт вызывающий (контроллер урока, фон,
/// экран прогресса): у reporter’а своего таймера нет.
class ProgressReporter {
  ProgressReporter({
    required ProgressLocalDataSource local,
    required ProgressRemoteDataSource remote,
    this.onSummary,
  }) : _local = local,
       _remote = remote;

  final ProgressLocalDataSource _local;
  final ProgressRemoteDataSource _remote;

  /// Свежая сводка после успешного события — чтобы экран прогресса не делал
  /// лишний `GET /v1/progress`.
  final void Function(ProgressSummary summary)? onSummary;

  bool _flushing = false;

  /// Прослушанные миллисекунды (wall-clock).
  Future<void> addListened(int ms) => _local.addListened(ms);

  /// Один доигранный проход отрезка: `+1` каждому его сегменту.
  Future<void> recordSegmentPass(
    String lessonId,
    Iterable<int> segmentIndices,
  ) async {
    for (final index in segmentIndices) {
      await _local.bumpSegment(lessonId, index);
    }
  }

  /// Отправляет накопленную дельту. [lessonId] добавляет урок в «последние 5»
  /// (`recent_lesson_ids`) — только для видимого урока, который мы и открыли.
  Future<void> flush({String? lessonId}) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final pending = await _local.readPending();
      if (pending.isEmpty) return;
      final summary = await _remote.reportEvents(
        listenedMs: pending.listenedMs > 0 ? pending.listenedMs : null,
        segmentRepeats: pending.segmentRepeats > 0
            ? pending.segmentRepeats
            : null,
        lessonId: lessonId,
      );
      // Вычитаем ровно отправленное: новая активность во время запроса не
      // теряется.
      await _local.subtractPending(pending.listenedMs, pending.segmentRepeats);
      onSummary?.call(summary);
    } catch (_) {
      // Сеть или сервер отвергли — дельта осталась, повторим позже.
    } finally {
      _flushing = false;
    }
  }

  /// Если по локальным счётчикам урок пройден (каждый сегмент повторён
  /// [completionReps] раз) и отметку ещё не слали — шлёт `completed` один раз.
  Future<void> reportCompletedIfDone({
    required String lessonId,
    required int segmentCount,
    required int completionReps,
  }) async {
    try {
      if (await _local.isCompletedSent(lessonId)) return;
      final reps = await _local.readReps(lessonId);
      if (!progressIsComplete(reps, segmentCount, completionReps)) return;
      final summary = await _remote.reportEvents(
        completed: true,
        lessonId: lessonId,
      );
      await _local.markCompletedSent(lessonId);
      onSummary?.call(summary);
    } catch (_) {
      // Не удалось отметить — флаг не ставим, попробуем в следующий раз.
    }
  }
}
