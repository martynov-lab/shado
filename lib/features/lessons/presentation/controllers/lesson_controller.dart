import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../progress/data/progress_reporter.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment.dart';
import '../../domain/entities/segment_range.dart';
import 'lesson_providers.dart';

/// Один экземпляр плеера на экран урока: уходим с экрана — плеер уничтожается.
final lessonAudioPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, lessonId) {
      final player = AudioPlayer();
      ref.onDispose(player.dispose);
      return player;
    });

/// Позиция воспроизведения (мс) для курсора на дорожке.
///
/// Её пишет контроллер из того же потока позиции, что стережёт границы куска, —
/// поэтому курсор идёт при любом запуске (и кнопкой плеера, и тапом по
/// сегменту). Отдельный провайдер, чтобы на каждом тике перестраивалась только
/// волна, а не весь экран урока.
class LessonPositionNotifier extends Notifier<int> {
  LessonPositionNotifier(this.lessonId);

  final String lessonId;

  @override
  int build() => 0;

  void set(int ms) => state = ms;
}

final lessonPositionMsProvider = NotifierProvider.autoDispose
    .family<LessonPositionNotifier, int, String>(LessonPositionNotifier.new);

/// Состояние экрана урока.
class LessonState {
  const LessonState({
    required this.lesson,
    required this.speed,
    this.activeRange,
    this.isPlaying = false,
    this.isLooped = false,
    this.isSelecting = false,
    this.selection,
    this.committedRange,
    this.focusedIndex,
  });

  final Lesson lesson;
  final double speed;

  /// Что заряжено в плеер: один кусок или отрезок из нескольких. Играет или
  /// стоит — смотри [isPlaying].
  final SegmentRange? activeRange;

  final bool isPlaying;

  /// Один тумблер повтора на весь плеер: держится при переходе между кусками и
  /// применяется к тому, что заряжено сейчас — куску или закреплённому отрезку.
  final bool isLooped;

  /// Включён режим выбора: на плитках появляются галочки, а тап по плитке
  /// набирает выделение. Вне режима галочки не занимают место перед текстом.
  final bool isSelecting;

  /// Выбранные куски: только соседние, зато играются подряд одним фрагментом.
  final SegmentRange? selection;

  /// Закреплённый в плеере отрезок из нескольких кусков: показывает их общий
  /// текст и играет общий фрагмент. `null` — плеер показывает один кусок
  /// [currentIndex].
  final SegmentRange? committedRange;

  /// Кусок под клавиатурой: по нему ходят стрелки, его играет пробел. `null` —
  /// клавиатурой ещё не пользовались.
  final int? focusedIndex;

  bool get isSlow => speed == kSlowSpeed;

  /// Текущий кусок для панели плеера: тот, что под клавиатурой, или первый,
  /// пока стрелками не пользовались. Всегда в границах разбивки.
  int get currentIndex {
    final count = lesson.segmentCount;
    if (count == 0) return 0;
    return (focusedIndex ?? 0).clamp(0, count - 1);
  }

  Segment get currentSegment => lesson.segments[currentIndex];

  /// Что показывает плеер: закреплённый отрезок или один текущий кусок.
  SegmentRange get playerRange =>
      committedRange ?? SegmentRange.single(currentIndex);

  /// Общий текст показанного отрезка: тексты его кусков подряд через пробел.
  String get playerText {
    final range = playerRange;
    final segments = lesson.segments;
    return [
      for (var i = range.start; i <= range.end && i < segments.length; i++)
        segments[i].text,
    ].join(' ');
  }

  int get playerStartMs => lesson.segments[playerRange.start].startMs;

  int get playerEndMs => lesson.segments[playerRange.end].endMs;

  /// Плеер играет ровно то, что показывает, — а не кусок мимо показанного.
  bool get isPlayerPlaying => isPlaying && activeRange == playerRange;

  bool get canGoPrevious => playerRange.start > 0;

  bool get canGoNext => playerRange.end < lesson.segmentCount - 1;

  bool isSegmentActive(int index) => activeRange?.contains(index) ?? false;

  bool isSegmentPlaying(int index) => isPlaying && isSegmentActive(index);

  bool isSegmentSelected(int index) => selection?.contains(index) ?? false;

  /// Играет именно выбранный отрезок, а не отдельный кусок мимо выделения.
  bool get isSelectionPlaying =>
      isPlaying && selection != null && activeRange == selection;

  /// Сколько звучит выделение целиком.
  int get selectionDurationMs {
    final range = selection;
    if (range == null) return 0;
    final segments = lesson.segments;
    if (range.end >= segments.length) return 0;
    return segments[range.end].endMs - segments[range.start].startMs;
  }

  LessonState copyWith({
    Lesson? lesson,
    double? speed,
    SegmentRange? activeRange,
    bool clearActiveRange = false,
    bool? isPlaying,
    bool? isLooped,
    bool? isSelecting,
    SegmentRange? selection,
    bool clearSelection = false,
    SegmentRange? committedRange,
    bool clearCommittedRange = false,
    int? focusedIndex,
  }) {
    return LessonState(
      lesson: lesson ?? this.lesson,
      speed: speed ?? this.speed,
      activeRange: clearActiveRange ? null : (activeRange ?? this.activeRange),
      isPlaying: isPlaying ?? this.isPlaying,
      isLooped: isLooped ?? this.isLooped,
      isSelecting: isSelecting ?? this.isSelecting,
      selection: clearSelection ? null : (selection ?? this.selection),
      committedRange: clearCommittedRange
          ? null
          : (committedRange ?? this.committedRange),
      focusedIndex: focusedIndex ?? this.focusedIndex,
    );
  }
}

/// Как часто сверяться с позицией, стерегая конец отрезка. На 10 мс перебег за
/// границу — единицы миллисекунд, на слух этого нет.
const _positionTick = Duration(milliseconds: 10);

/// Проигрывание кусков, зацикливание, скорость и выбор нескольких кусков.
/// Разметка правится на отдельном экране — здесь урок уже нарезан.
class LessonController extends AsyncNotifier<LessonState> {
  LessonController(this.lessonId);

  final String lessonId;

  /// Скорость, флаги loop и точка отсчёта выделения живут в контроллере: они
  /// переживают пересборку [build], в отличие от состояния.
  double _speed = kNormalSpeed;

  /// Один тумблер повтора на весь плеер: он держится при переходе между кусками
  /// и применяется к тому, что заряжено сейчас (кусок или закреплённый отрезок).
  bool _loopEnabled = false;

  /// Кусок, с которого начали выделять: Shift + стрелки растят выделение от
  /// него в обе стороны.
  int? _selectionAnchor;

  /// Файл, заряженный в плеер. Заряжаем его целиком и один раз на урок: переход
  /// между кусками — это seek, а не новый источник.
  String? _loadedPath;

  /// Зацикливать ли то, что заряжено сейчас. Флаг снимается с куска или с
  /// выделения в момент пуска — у них разные тумблеры.
  bool _activeLooped = false;

  /// Границу отрезка уже поймали и отрабатываем: позиция ещё пару тиков
  /// постоит за ней, и второй раз перезапускать круг не нужно.
  bool _atBoundary = false;

  /// Последняя позиция, отданная на дорожку: прореживаем поток до ~25 кадров/с.
  int _lastWaveMs = -1000;

  /// Момент, с которого плеер играет непрерывно, — для подсчёта прослушанного
  /// времени (wall-clock). `null` — сейчас не играет.
  DateTime? _playStartedAt;

  /// Когда последний раз засчитали проход отрезка: дедуп near-simultaneous
  /// срабатываний сторожа границы и «плеер доиграл файл».
  DateTime? _lastPassAt;

  /// Периодически досылает накопленную активность, пока открыт урок.
  Timer? _flushTimer;

  ProgressReporter get _reporter => ref.read(progressReporterProvider);

  AudioPlayer get _player => ref.read(lessonAudioPlayerProvider(lessonId));

  @override
  Future<LessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    // Именно watch: плеер под autoDispose и должен жить, пока жив контроллер.
    final player = ref.watch(lessonAudioPlayerProvider(lessonId));
    final stateSubscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(stateSubscription.cancel);
    // steps здесь не важен: одинаковые min и max держат период ровно тиком.
    final positionSubscription = player
        .createPositionStream(
          steps: 1,
          minPeriod: _positionTick,
          maxPeriod: _positionTick,
        )
        .listen(_onPosition);
    ref.onDispose(positionSubscription.cancel);
    // Порог пройденности понадобится при проверке «пройдено» — прогреваем кеш.
    ref.read(completionRepsProvider);
    // Досылаем накопленную активность периодически и при уходе с экрана.
    // Репортёр захватываем сейчас: в onDispose обращаться к ref уже нельзя
    // (Riverpod 3 это запрещает), а досыл при уходе должен пройти по живой ссылке.
    final reporter = _reporter;
    _flushTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => reporter.flush(lessonId: lessonId),
    );
    ref.onDispose(() {
      _flushTimer?.cancel();
      unawaited(_flushOnLeave(reporter));
    });
    return LessonState(lesson: lesson, speed: _speed, isLooped: _loopEnabled);
  }

  void _onPlayerState(PlayerState playerState) {
    final current = state.value;
    if (current == null) return;
    final finished = playerState.processingState == ProcessingState.completed;
    _updateClock(playerState.playing && !finished);
    // Конец последнего куска может совпасть с концом файла — тогда границу
    // стеречь уже нечем, потому что позиция дальше не тикает.
    if (finished && _activeLooped && current.activeRange != null) {
      _recordPass(current.activeRange!);
      unawaited(_rewindTo(current, current.activeRange!, play: true));
      return;
    }
    final isPlaying = playerState.playing && !finished;
    if (isPlaying != current.isPlaying) {
      state = AsyncValue.data(current.copyWith(isPlaying: isPlaying));
    }
  }

  /// Сторож конца отрезка.
  ///
  /// Файл заряжен целиком, поэтому конец куска — это не конец дорожки, а просто
  /// позиция, до которой играем. Так круг и начинается там, где надо: у
  /// `ClippingAudioSource` с `LoopMode.one` на media_kit новый круг уезжает в
  /// начало файла, мимо выбранного отрезка.
  void _onPosition(Duration position) {
    _pushWavePosition(position.inMilliseconds);
    final current = state.value;
    final range = current?.activeRange;
    if (current == null || range == null || _atBoundary) return;
    final segments = current.lesson.segments;
    if (range.end >= segments.length) return;
    if (position.inMilliseconds < segments[range.end].endMs) return;
    _atBoundary = true;
    // Отрезок доигран до конца — засчитываем проход каждому его сегменту.
    _recordPass(range);
    unawaited(_rewindTo(current, range, play: _activeLooped));
  }

  /// Отдаёт позицию на дорожку, но не чаще ~25 кадров/с: поток тикает каждые
  /// 10 мс, а волне такой частоты не нужно.
  void _pushWavePosition(int ms) {
    if ((ms - _lastWaveMs).abs() < 40) return;
    _lastWaveMs = ms;
    ref.read(lessonPositionMsProvider(lessonId).notifier).set(ms);
  }

  // --- Инструментирование прогресса ------------------------------------------

  /// Копит прослушанное время по интервалам воспроизведения (wall-clock).
  void _updateClock(bool playing) {
    if (playing) {
      _playStartedAt ??= DateTime.now();
      return;
    }
    final started = _playStartedAt;
    if (started == null) return;
    _playStartedAt = null;
    final ms = DateTime.now().difference(started).inMilliseconds;
    if (ms > 0) unawaited(_reporter.addListened(ms));
  }

  /// Засчитывает один доигранный проход отрезка: `+1` каждому его сегменту.
  /// Дедуп по времени гасит двойное срабатывание сторожа границы и «доиграл
  /// файл» на последнем куске.
  void _recordPass(SegmentRange range) {
    final now = DateTime.now();
    final last = _lastPassAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 250)) {
      return;
    }
    _lastPassAt = now;
    final indices = [for (var i = range.start; i <= range.end; i++) i];
    unawaited(
      _reporter
          .recordSegmentPass(lessonId, indices)
          .then((_) => _maybeReportCompletion()),
    );
  }

  /// Проверяет, не пройден ли урок целиком, и один раз шлёт `completed`.
  void _maybeReportCompletion() {
    final current = state.value;
    if (current == null) return;
    // Порог ещё не загрузился — проверим на следующем проходе.
    final target = ref.read(completionRepsProvider).asData?.value;
    if (target == null) return;
    unawaited(
      _reporter.reportCompletedIfDone(
        lessonId: lessonId,
        segmentCount: current.lesson.segmentCount,
        completionReps: target,
      ),
    );
  }

  /// Финализирует текущий интервал прослушивания и досылает активность при
  /// уходе с экрана. Репортёр приходит извне: во время dispose читать его из
  /// `ref` уже нельзя.
  Future<void> _flushOnLeave(ProgressReporter reporter) async {
    final started = _playStartedAt;
    _playStartedAt = null;
    if (started != null) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (ms > 0) await reporter.addListened(ms);
    }
    await reporter.flush(lessonId: lessonId);
  }

  /// Ставит дорожку на начало отрезка: новый круг, если [play], иначе стоп там,
  /// откуда естественно начать в следующий раз.
  Future<void> _rewindTo(
    LessonState current,
    SegmentRange range, {
    required bool play,
  }) async {
    final player = _player;
    final segments = current.lesson.segments;
    try {
      if (range.start >= segments.length) return;
      if (!play) await player.pause();
      // Играющему плееру seek воспроизведение не рвёт — круг выходит без щелчка.
      await player.seek(Duration(milliseconds: segments[range.start].startMs));
      // Доигравший до конца файла плеер остаётся «играющим», и звук после seek
      // продолжится сам; поднимать его нужно только по-настоящему стоящему.
      if (play && !player.playing) unawaited(player.play());
    } finally {
      _atBoundary = false;
    }
  }

  // --- Воспроизведение -------------------------------------------------------

  /// Пуск или остановка отрезка [range]: если он уже заряжен — тумблер, иначе
  /// заряжаем и играем с начала.
  Future<void> _togglePlayRange(LessonState current, SegmentRange range) async {
    if (current.activeRange != range) {
      await _start(current, range, loop: _loopEnabled);
      return;
    }
    await _toggleActive(current);
  }

  /// Тумблер «играть / остановить» для куска. Запуск другого куска
  /// останавливает текущий.
  Future<void> togglePlay(int index) async {
    final current = state.value;
    if (current == null) return;
    await _togglePlayRange(current, SegmentRange.single(index));
  }

  /// Тумблер для выбранного отрезка: играет его подряд, одним фрагментом.
  Future<void> togglePlaySelection() async {
    final current = state.value;
    final selection = current?.selection;
    if (current == null || selection == null) return;
    await _togglePlayRange(current, selection);
  }

  /// Пробел: играет набранный отрезок, а иначе — то, что показывает плеер.
  Future<void> togglePlayFocused() async {
    final current = state.value;
    if (current == null) return;
    final selection = current.selection;
    if (selection != null && !selection.isSingle) {
      await togglePlaySelection();
      return;
    }
    await togglePlayCurrent();
  }

  /// Играет/останавливает то, что показывает плеер (кусок или закреплённый
  /// отрезок) — большая кнопка на панели плеера.
  Future<void> togglePlayCurrent() async {
    final current = state.value;
    if (current == null) return;
    await _togglePlayRange(current, current.playerRange);
  }

  /// Переход к одному куску — тап по строке сегмента, а также prev/next. Снимает
  /// закреплённый отрезок: плеер показывает этот кусок. Если что-то играло,
  /// новый кусок тоже заиграет (и курсор дорожки поедет по нему); иначе кусок
  /// просто заряжается, а курсор встаёт в его начало.
  Future<void> goToSegment(int index) async {
    final current = state.value;
    if (current == null) return;
    if (index < 0 || index >= current.lesson.segmentCount) return;
    if (index == current.currentIndex && current.committedRange == null) return;
    final wasPlaying = current.isPlayerPlaying;
    setFocus(index);
    if (wasPlaying) await togglePlay(index);
  }

  Future<void> next() => goToSegment((state.value?.playerRange.end ?? 0) + 1);

  Future<void> previous() =>
      goToSegment((state.value?.playerRange.start ?? 0) - 1);

  /// Переключает скорость между нормальной и медленной — чип на панели плеера.
  Future<void> cycleSpeed() async {
    final current = state.value;
    if (current == null) return;
    await setSpeed(current.speed == kNormalSpeed ? kSlowSpeed : kNormalSpeed);
  }

  /// Пуск или остановка того, что уже заряжено в плеер.
  Future<void> _toggleActive(LessonState current) async {
    final range = current.activeRange;
    if (current.isPlaying) {
      // Именно остановка, а не пауза: кусок короткий, и следующий пуск
      // естественнее начать с его начала, чем с середины фразы.
      if (range != null) await _rewindTo(current, range, play: false);
      return;
    }
    // Последний кусок мог кончиться вместе с файлом: с этого места играть
    // нечего, поэтому начинаем отрезок заново.
    if (range != null && _player.processingState == ProcessingState.completed) {
      await _rewindTo(current, range, play: true);
      return;
    }
    _atBoundary = false;
    unawaited(_player.play());
  }

  /// Заряжает отрезок и запускает его с начала.
  ///
  /// Куски идут встык, поэтому отрезок — это один непрерывный фрагмент аудио:
  /// подряд он играет сам, а конец отрезка стережёт [_onPosition].
  Future<void> _start(
    LessonState current,
    SegmentRange range, {
    required bool loop,
  }) async {
    final segments = current.lesson.segments;
    if (range.end >= segments.length) return;
    final player = _player;
    await _ensureSource(current.lesson.audioPath);
    _activeLooped = loop;
    _atBoundary = false;
    await player.seek(Duration(milliseconds: segments[range.start].startMs));
    await player.setSpeed(_speed);
    state = AsyncValue.data(
      current.copyWith(activeRange: range, isPlaying: true),
    );
    // play() завершается только по окончании воспроизведения — не ждём его.
    unawaited(player.play());
  }

  /// Заряжает файл урока целиком — один раз на урок.
  Future<void> _ensureSource(String audioPath) async {
    if (_loadedPath == audioPath) return;
    final player = _player;
    await player.stop();
    await player.setAudioSource(AudioSource.file(audioPath));
    // Цикл сводится к seek в начало отрезка: LoopMode плееру больше не нужен.
    await player.setLoopMode(LoopMode.off);
    _loadedPath = audioPath;
  }

  /// Тумблер повтора плеера: единый для куска и закреплённого отрезка. Держится
  /// при переходе между кусками и на лету включается/выключается для того, что
  /// заряжено сейчас.
  void toggleLoop() {
    final current = state.value;
    if (current == null) return;
    _loopEnabled = !_loopEnabled;
    if (current.activeRange != null) _activeLooped = _loopEnabled;
    state = AsyncValue.data(current.copyWith(isLooped: _loopEnabled));
  }

  /// Скорость на весь урок: применяется на лету и к последующим запускам.
  Future<void> setSpeed(double speed) async {
    final current = state.value;
    if (current == null || current.speed == speed) return;
    _speed = speed;
    state = AsyncValue.data(current.copyWith(speed: speed));
    await _player.setSpeed(speed);
  }

  // --- Выбор кусков ----------------------------------------------------------

  /// Включает режим выбора: до него галочки места перед текстом не занимают.
  void startSelecting() {
    final current = state.value;
    if (current == null || current.isSelecting) return;
    state = AsyncValue.data(current.copyWith(isSelecting: true));
  }

  /// Выходит из режима выбора, снимая выделение: спрятанное выделение
  /// продолжало бы отвечать за пробел и держать нижнюю панель.
  void stopSelecting() {
    final current = state.value;
    if (current == null || !current.isSelecting) return;
    _selectionAnchor = null;
    state = AsyncValue.data(
      current.copyWith(isSelecting: false, clearSelection: true),
    );
  }

  /// Заряжает набранный выбор в плеер прямо по ходу выбора: отрезок из
  /// нескольких кусков становится закреплённым (плеер показывает их общий текст и
  /// фрагмент), один кусок — текущим. Звук здесь не запускаем — играть или нет
  /// решает кнопка плеера.
  void _applySelection(LessonState current, SegmentRange? selection) {
    final isRange = selection != null && !selection.isSingle;
    state = AsyncValue.data(
      current.copyWith(
        isSelecting: true,
        selection: selection,
        clearSelection: selection == null,
        committedRange: isRange ? selection : null,
        clearCommittedRange: !isRange,
        focusedIndex: selection?.start,
      ),
    );
  }

  /// Завершение выбора кнопкой «Готово»: выходим из режима, но заряженный в
  /// плеер отрезок остаётся — играть его будет кнопка плеера. Возвращает `true`,
  /// если что-то было выбрано, — тогда мобильный лист сегментов можно закрыть.
  bool finishSelecting() {
    final current = state.value;
    if (current == null) return false;
    final hadSelection =
        current.selection != null || current.committedRange != null;
    _selectionAnchor = null;
    state = AsyncValue.data(
      current.copyWith(isSelecting: false, clearSelection: true),
    );
    return hadSelection;
  }

  /// Тап по куску в режиме выбора. Первый тап ставит якорь, второй задаёт второй
  /// конец отрезка — все куски между ними выбираются сами. Повторный тап по
  /// единственному выбранному куску снимает выбор.
  void toggleSelection(int index) {
    final current = state.value;
    if (current == null) return;
    final anchor = _selectionAnchor;
    final selection = current.selection;
    final SegmentRange? next;
    if (anchor == null || selection == null) {
      next = SegmentRange.single(index);
      _selectionAnchor = index;
    } else if (index == anchor && selection.isSingle) {
      next = null;
      _selectionAnchor = null;
    } else {
      next = SegmentRange.between(anchor, index);
    }
    _applySelection(current, next);
  }

  void selectAll() {
    final current = state.value;
    if (current == null) return;
    final count = current.lesson.segmentCount;
    if (count == 0) return;
    _selectionAnchor = 0;
    _applySelection(current, SegmentRange(0, count - 1));
  }

  void clearSelection() {
    final current = state.value;
    if (current == null || current.selection == null) return;
    _selectionAnchor = null;
    _applySelection(current, null);
  }

  /// Ходит по кускам стрелками. С [extend] (Shift) выделение растёт от куска, с
  /// которого начали выделять.
  void moveFocus(int delta, {bool extend = false}) {
    final current = state.value;
    if (current == null) return;
    final count = current.lesson.segmentCount;
    if (count == 0) return;
    final from = current.focusedIndex ?? (delta > 0 ? -1 : count);
    final index = (from + delta).clamp(0, count - 1);
    if (!extend) {
      state = AsyncValue.data(
        current.copyWith(focusedIndex: index, clearCommittedRange: true),
      );
      return;
    }
    final anchor = _selectionAnchor ?? current.focusedIndex ?? index;
    _selectionAnchor = anchor;
    final selection = SegmentRange.between(anchor, index);
    // Курсор ведём по подвижному концу, а в плеер сразу заряжаем весь отрезок.
    final isRange = !selection.isSingle;
    state = AsyncValue.data(
      current.copyWith(
        isSelecting: true,
        focusedIndex: index,
        selection: selection,
        committedRange: isRange ? selection : null,
        clearCommittedRange: !isRange,
      ),
    );
  }

  void setFocus(int index) {
    final current = state.value;
    if (current == null) return;
    if (current.focusedIndex == index && current.committedRange == null) return;
    // Переход к одному куску снимает закреплённый отрезок.
    state = AsyncValue.data(
      current.copyWith(focusedIndex: index, clearCommittedRange: true),
    );
  }

  /// Перечитывает урок после правки на отдельном экране: там могло измениться
  /// и число кусков, поэтому старые индексы (активный отрезок, выделение,
  /// зацикленные куски) больше не годятся.
  Future<void> reload() async {
    await _player.stop();
    _loopEnabled = false;
    _selectionAnchor = null;
    _activeLooped = false;
    _atBoundary = false;
    // Файл могли подменить вместе с разбивкой — заряжаем заново.
    _loadedPath = null;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final lesson = await ref.read(getLessonProvider)(lessonId);
      return LessonState(lesson: lesson, speed: _speed);
    });
  }
}

final lessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LessonController, LessonState, String>(LessonController.new);
