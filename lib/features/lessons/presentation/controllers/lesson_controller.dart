import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_range.dart';
import 'lesson_providers.dart';

/// Один экземпляр плеера на экран урока: уходим с экрана — плеер уничтожается.
final lessonAudioPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, lessonId) {
      final player = AudioPlayer();
      ref.onDispose(player.dispose);
      return player;
    });

/// Состояние экрана урока.
class LessonState {
  const LessonState({
    required this.lesson,
    required this.speed,
    this.activeRange,
    this.isPlaying = false,
    this.loopedSegments = const {},
    this.selection,
    this.isSelectionLooped = false,
    this.focusedIndex,
  });

  final Lesson lesson;
  final double speed;

  /// Что заряжено в плеер: один кусок или отрезок из нескольких. Играет или
  /// стоит — смотри [isPlaying].
  final SegmentRange? activeRange;

  final bool isPlaying;

  /// Индексы кусков с включённым зацикливанием: тумблер на самой плитке. У
  /// выбранного отрезка свой тумблер — [isSelectionLooped].
  final Set<int> loopedSegments;

  /// Выбранные куски: только соседние, зато играются подряд одним фрагментом.
  final SegmentRange? selection;

  final bool isSelectionLooped;

  /// Кусок под клавиатурой: по нему ходят стрелки, его играет пробел. `null` —
  /// клавиатурой ещё не пользовались.
  final int? focusedIndex;

  bool get isSlow => speed == kSlowSpeed;

  bool isSegmentActive(int index) => activeRange?.contains(index) ?? false;

  bool isSegmentPlaying(int index) => isPlaying && isSegmentActive(index);

  bool isSegmentLooped(int index) => loopedSegments.contains(index);

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
    Set<int>? loopedSegments,
    SegmentRange? selection,
    bool clearSelection = false,
    bool? isSelectionLooped,
    int? focusedIndex,
  }) {
    return LessonState(
      lesson: lesson ?? this.lesson,
      speed: speed ?? this.speed,
      activeRange: clearActiveRange ? null : (activeRange ?? this.activeRange),
      isPlaying: isPlaying ?? this.isPlaying,
      loopedSegments: loopedSegments ?? this.loopedSegments,
      selection: clearSelection ? null : (selection ?? this.selection),
      isSelectionLooped: isSelectionLooped ?? this.isSelectionLooped,
      focusedIndex: focusedIndex ?? this.focusedIndex,
    );
  }
}

/// Проигрывание кусков, зацикливание, скорость и выбор нескольких кусков.
/// Разметка правится на отдельном экране — здесь урок уже нарезан.
class LessonController extends AsyncNotifier<LessonState> {
  LessonController(this.lessonId);

  final String lessonId;

  /// Скорость, флаги loop и точка отсчёта выделения живут в контроллере: они
  /// переживают пересборку [build], в отличие от состояния.
  double _speed = kNormalSpeed;
  final Set<int> _loopedSegments = <int>{};
  bool _selectionLooped = false;

  /// Кусок, с которого начали выделять: Shift + стрелки растят выделение от
  /// него в обе стороны.
  int? _selectionAnchor;

  AudioPlayer get _player => ref.read(lessonAudioPlayerProvider(lessonId));

  @override
  Future<LessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    // Именно watch: плеер под autoDispose и должен жить, пока жив контроллер.
    final player = ref.watch(lessonAudioPlayerProvider(lessonId));
    final subscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(subscription.cancel);
    return LessonState(
      lesson: lesson,
      speed: _speed,
      loopedSegments: Set.unmodifiable(_loopedSegments),
      isSelectionLooped: _selectionLooped,
    );
  }

  void _onPlayerState(PlayerState playerState) {
    final current = state.value;
    if (current == null) return;
    final isPlaying =
        playerState.playing &&
        playerState.processingState != ProcessingState.completed;
    if (isPlaying != current.isPlaying) {
      state = AsyncValue.data(current.copyWith(isPlaying: isPlaying));
    }
  }

  // --- Воспроизведение -------------------------------------------------------

  /// Тумблер «играть / остановить» для куска. Запуск другого куска
  /// останавливает текущий.
  Future<void> togglePlay(int index) async {
    final current = state.value;
    if (current == null) return;
    final range = SegmentRange.single(index);
    if (current.activeRange != range) {
      await _start(current, range, loop: _loopedSegments.contains(index));
      return;
    }
    await _toggleActive(current);
  }

  /// Тумблер для выбранного отрезка: играет его подряд, одним фрагментом.
  Future<void> togglePlaySelection() async {
    final current = state.value;
    final selection = current?.selection;
    if (current == null || selection == null) return;
    if (current.activeRange != selection) {
      await _start(current, selection, loop: _selectionLooped);
      return;
    }
    await _toggleActive(current);
  }

  /// Пробел: играет выбранное, а если выбора нет — кусок под фокусом.
  Future<void> togglePlayFocused() async {
    final current = state.value;
    if (current == null) return;
    final selection = current.selection;
    if (selection != null && !selection.isSingle) {
      await togglePlaySelection();
      return;
    }
    await togglePlay(selection?.start ?? current.focusedIndex ?? 0);
  }

  /// Пуск или остановка того, что уже заряжено в плеер.
  Future<void> _toggleActive(LessonState current) async {
    final player = _player;
    if (current.isPlaying) {
      await player.pause();
      // Именно остановка, а не пауза: кусок короткий, и следующий пуск
      // естественнее начать с его начала, чем с середины фразы.
      await player.seek(Duration.zero);
      return;
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }

  /// Заряжает отрезок в плеер и запускает его.
  ///
  /// Куски идут встык, поэтому отрезок — это один непрерывный фрагмент аудио:
  /// подряд он играет сам, а зацикливание — обычный `LoopMode.one`.
  Future<void> _start(
    LessonState current,
    SegmentRange range, {
    required bool loop,
  }) async {
    final segments = current.lesson.segments;
    if (range.end >= segments.length) return;
    final player = _player;
    await player.stop();
    await player.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.file(current.lesson.audioPath),
        start: Duration(milliseconds: segments[range.start].startMs),
        end: Duration(milliseconds: segments[range.end].endMs),
      ),
    );
    await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await player.setSpeed(_speed);
    state = AsyncValue.data(
      current.copyWith(activeRange: range, isPlaying: true),
    );
    // play() завершается только по окончании воспроизведения — не ждём его.
    unawaited(player.play());
  }

  Future<void> toggleLoop(int index) async {
    final current = state.value;
    if (current == null) return;
    final enabled = !_loopedSegments.contains(index);
    if (enabled) {
      _loopedSegments.add(index);
    } else {
      _loopedSegments.remove(index);
    }
    if (current.activeRange == SegmentRange.single(index)) {
      await _player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);
    }
    state = AsyncValue.data(
      current.copyWith(loopedSegments: Set.unmodifiable(_loopedSegments)),
    );
  }

  /// Зацикливание выбранного отрезка. На лету, если он уже играет.
  Future<void> toggleSelectionLoop() async {
    final current = state.value;
    final selection = current?.selection;
    if (current == null || selection == null) return;
    _selectionLooped = !_selectionLooped;
    state = AsyncValue.data(
      current.copyWith(isSelectionLooped: _selectionLooped),
    );
    if (current.activeRange == selection) {
      await _player.setLoopMode(_selectionLooped ? LoopMode.one : LoopMode.off);
      return;
    }
    // Отрезок ещё не заряжен — включённый повтор сразу и запускаем.
    if (_selectionLooped) await togglePlaySelection();
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

  /// Тап по галочке куска. Выделение остаётся непрерывным — правила в
  /// [SegmentRange.toggled].
  void toggleSelection(int index) {
    final current = state.value;
    if (current == null) return;
    final selection = SegmentRange.toggled(current.selection, index);
    _selectionAnchor = selection == null ? null : index;
    state = AsyncValue.data(
      current.copyWith(
        selection: selection,
        clearSelection: selection == null,
        focusedIndex: index,
      ),
    );
  }

  void selectAll() {
    final current = state.value;
    if (current == null) return;
    final count = current.lesson.segmentCount;
    if (count == 0) return;
    _selectionAnchor = 0;
    state = AsyncValue.data(
      current.copyWith(selection: SegmentRange(0, count - 1)),
    );
  }

  void clearSelection() {
    final current = state.value;
    if (current == null || current.selection == null) return;
    _selectionAnchor = null;
    state = AsyncValue.data(current.copyWith(clearSelection: true));
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
      state = AsyncValue.data(current.copyWith(focusedIndex: index));
      return;
    }
    final anchor = _selectionAnchor ?? current.focusedIndex ?? index;
    _selectionAnchor = anchor;
    state = AsyncValue.data(
      current.copyWith(
        focusedIndex: index,
        selection: SegmentRange.between(anchor, index),
      ),
    );
  }

  void setFocus(int index) {
    final current = state.value;
    if (current == null || current.focusedIndex == index) return;
    state = AsyncValue.data(current.copyWith(focusedIndex: index));
  }

  /// Перечитывает урок после правки на отдельном экране: там могло измениться
  /// и число кусков, поэтому старые индексы (активный отрезок, выделение,
  /// зацикленные куски) больше не годятся.
  Future<void> reload() async {
    await _player.stop();
    _loopedSegments.clear();
    _selectionAnchor = null;
    _selectionLooped = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final lesson = await ref.read(getLessonProvider)(lessonId);
      return LessonState(lesson: lesson, speed: _speed);
    });
  }
}

final lessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LessonController, LessonState, String>(LessonController.new);
