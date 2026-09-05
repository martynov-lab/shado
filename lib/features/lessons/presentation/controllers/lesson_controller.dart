import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/audio/audio_service_setup.dart';
import '../../../../core/audio/lesson_remote_control.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../progress/data/progress_reporter.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';
import '../../../settings/domain/entities/playback_settings.dart';
import '../../../settings/presentation/controllers/playback_settings_controller.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment.dart';
import '../../domain/entities/segment_range.dart';
import 'lesson_providers.dart';

/// One player per lesson screen; it is disposed when the screen closes.
final lessonAudioPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, lessonId) {
      final player = AudioPlayer();
      ref.onDispose(player.dispose);
      return player;
    });

/// Playback position in milliseconds for the track cursor.
class LessonPositionNotifier extends Notifier<int> {
  LessonPositionNotifier(this.lessonId);

  final String lessonId;

  @override
  int build() => 0;

  void set(int ms) => state = ms;
}

final lessonPositionMsProvider = NotifierProvider.autoDispose
    .family<LessonPositionNotifier, int, String>(LessonPositionNotifier.new);

/// State of the lesson screen.
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
    this.countdown,
  });

  final Lesson lesson;
  final double speed;

  /// What is loaded into the player: one segment or a range.
  final SegmentRange? activeRange;

  final bool isPlaying;

  /// Whether repeat is on for the loaded range.
  final bool isLooped;

  /// Whether segment selection mode is on.
  final bool isSelecting;

  /// Selected adjacent segments.
  final SegmentRange? selection;

  /// Pinned multi-segment range; `null` means the player shows a single
  /// segment [currentIndex].
  final SegmentRange? committedRange;

  /// Keyboard-focused segment; `null` when the keyboard was never used.
  final int? focusedIndex;

  /// Current countdown number; `null` when no countdown runs.
  final int? countdown;

  bool get isSlow => speed == kSlowSpeed;

  /// Segment for the player panel: the focused one or the first.
  int get currentIndex {
    final count = lesson.segmentCount;
    if (count == 0) return 0;
    return (focusedIndex ?? 0).clamp(0, count - 1);
  }

  Segment get currentSegment => lesson.segments[currentIndex];

  /// What the player shows: the pinned range or the current segment.
  SegmentRange get playerRange =>
      committedRange ?? SegmentRange.single(currentIndex);

  /// Texts of the shown range segments joined by spaces.
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

  /// Whether the player plays exactly what it shows.
  bool get isPlayerPlaying => isPlaying && activeRange == playerRange;

  bool get canGoPrevious => playerRange.start > 0;

  bool get canGoNext => playerRange.end < lesson.segmentCount - 1;

  bool isSegmentActive(int index) => activeRange?.contains(index) ?? false;

  bool isSegmentPlaying(int index) => isPlaying && isSegmentActive(index);

  bool isSegmentSelected(int index) => selection?.contains(index) ?? false;

  /// Whether the selected range itself is playing.
  bool get isSelectionPlaying =>
      isPlaying && selection != null && activeRange == selection;

  /// How long the whole selection sounds.
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
    int? countdown,
    bool clearCountdown = false,
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
      countdown: clearCountdown ? null : (countdown ?? this.countdown),
    );
  }
}

/// Position polling period while watching for the range end.
const _positionTick = Duration(milliseconds: 10);

/// Lesson playback: segments, looping, speed and multi-segment selection.
class LessonController extends AsyncNotifier<LessonState>
    implements LessonRemoteControl {
  LessonController(this.lessonId);

  final String lessonId;

  /// Playback speed; survives a [build] rebuild.
  double _speed = kNormalSpeed;

  /// Whether defaults were applied — only on the first lesson open.
  bool _defaultsApplied = false;

  /// How many range passes have played in the current cycle.
  int _passCount = 0;

  /// Token of the last action; a new one cancels a countdown and a pause.
  int _actionToken = 0;

  /// Player repeat toggle shared by a segment and a pinned range.
  bool _loopEnabled = false;

  /// Segment the selection started from.
  int? _selectionAnchor;

  /// Path of the file loaded into the player.
  String? _loadedPath;

  /// Whether the currently loaded range should loop.
  bool _activeLooped = false;

  /// The range boundary is already caught and being handled.
  bool _atBoundary = false;

  /// Last position pushed to the track.
  int _lastWaveMs = -1000;

  /// When continuous playback started; `null` while the player is stopped.
  DateTime? _playStartedAt;

  /// When a range pass was counted last.
  DateTime? _lastPassAt;

  /// Periodically flushes pending activity while the lesson is open.
  Timer? _flushTimer;

  ProgressReporter get _reporter => ref.read(progressReporterProvider);

  AudioPlayer get _player => ref.read(lessonAudioPlayerProvider(lessonId));

  /// Current playback settings.
  PlaybackSettings get _settings =>
      ref.read(playbackSettingsControllerProvider).value ??
      const PlaybackSettings();

  @override
  Future<LessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    // read, not watch: editing settings must not rebuild the player.
    final settings = await ref.read(
      playbackSettingsControllerProvider.future,
    );
    if (!_defaultsApplied) {
      _speed = settings.defaultSpeed;
      _defaultsApplied = true;
    }
    // watch: the player is autoDispose and lives with the notifier.
    final player = ref.watch(lessonAudioPlayerProvider(lessonId));
    final stateSubscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(stateSubscription.cancel);
    // Equal min and max keep the period exactly one tick.
    final positionSubscription = player
        .createPositionStream(
          steps: 1,
          minPeriod: _positionTick,
          maxPeriod: _positionTick,
        )
        .listen(_onPosition);
    ref.onDispose(positionSubscription.cancel);
    // Media session; on platforms without one the handler is null.
    final handler = ref.read(audioHandlerProvider);
    if (handler != null) {
      handler.attach(this);
      ref.onDispose(() => handler.detach(this));
      // Publish what is sounding and whether it plays to the session.
      listenSelf((_, next) {
        final data = next.value;
        if (data == null) return;
        handler.setNowPlaying(
          id: lessonId,
          title: data.lesson.title,
          album: data.playerText,
          duration: Duration(
            milliseconds: data.playerEndMs - data.playerStartMs,
          ),
          playing: data.isPlaying,
        );
      });
    }
    // Warm up the completion threshold cache.
    ref.read(completionRepsProvider);
    // Capture the reporter now: onDispose may no longer touch ref.
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
    // The last segment ends with the file, so the position stops ticking.
    if (finished && _activeLooped && current.activeRange != null) {
      unawaited(_onPassCompleted(current, current.activeRange!));
      return;
    }
    final isPlaying = playerState.playing && !finished;
    if (isPlaying != current.isPlaying) {
      state = AsyncValue.data(current.copyWith(isPlaying: isPlaying));
    }
  }

  /// Range end guard: the whole file is loaded, so the boundary is watched
  /// by position.
  void _onPosition(Duration position) {
    _pushWavePosition(position.inMilliseconds);
    final current = state.value;
    final range = current?.activeRange;
    if (current == null || range == null || _atBoundary) return;
    final segments = current.lesson.segments;
    if (range.end >= segments.length) return;
    if (position.inMilliseconds < segments[range.end].endMs) return;
    _atBoundary = true;
    unawaited(_onPassCompleted(current, range));
  }

  /// Counts a finished pass and decides between another lap and a stop.
  Future<void> _onPassCompleted(LessonState current, SegmentRange range) async {
    // Dedupes the boundary guard against the player finishing the file.
    if (!_recordPass(range)) return;
    _passCount++;
    final repeats = _settings.repeatsInCycle;
    // An endless cycle (0) runs while repeat is on.
    final again =
        _activeLooped && (repeats == kInfiniteRepeats || _passCount < repeats);
    if (!again) {
      _passCount = 0;
      await _rewindTo(current, range, play: false);
      return;
    }
    await _loopAgain(current, range);
  }

  /// Starts the next lap, honouring the pause between repeats.
  Future<void> _loopAgain(LessonState current, SegmentRange range) async {
    final segments = current.lesson.segments;
    if (range.start >= segments.length) {
      _atBoundary = false;
      return;
    }
    if (_settings.pauseBetweenRepeats) {
      final token = _actionToken;
      await _player.pause();
      // Seek to the range start so a play during the pause starts a lap.
      await _player.seek(Duration(milliseconds: segments[range.start].startMs));
      await Future<void>.delayed(const Duration(seconds: 1));
      if (token != _actionToken) {
        _atBoundary = false;
        return;
      }
    }
    final latest = state.value ?? current;
    await _rewindTo(latest, range, play: true);
  }

  /// Pushes the position to the track at most ~25 times per second.
  void _pushWavePosition(int ms) {
    if ((ms - _lastWaveMs).abs() < 40) return;
    _lastWaveMs = ms;
    ref.read(lessonPositionMsProvider(lessonId).notifier).set(ms);
  }

  // --- Progress instrumentation ----------------------------------------------

  /// Accumulates listened time across playback intervals.
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

  /// Counts a range pass for each segment; `false` when deduplicated.
  bool _recordPass(SegmentRange range) {
    final now = DateTime.now();
    final last = _lastPassAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 250)) {
      return false;
    }
    _lastPassAt = now;
    final indices = [for (var i = range.start; i <= range.end; i++) i];
    unawaited(
      _reporter
          .recordSegmentPass(lessonId, indices)
          .then((_) => _maybeReportCompletion()),
    );
    return true;
  }

  /// Checks whether the lesson is done and sends `completed` once.
  void _maybeReportCompletion() {
    final current = state.value;
    if (current == null) return;
    // The threshold has not loaded yet — check on the next pass.
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

  /// Flushes pending activity when leaving the screen.
  Future<void> _flushOnLeave(ProgressReporter reporter) async {
    final started = _playStartedAt;
    _playStartedAt = null;
    if (started != null) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (ms > 0) await reporter.addListened(ms);
    }
    await reporter.flush(lessonId: lessonId);
  }

  /// Seeks to the range start and, when [play], begins a lap.
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
      await player.seek(Duration(milliseconds: segments[range.start].startMs));
      // A finished player stays "playing" — only resume a stopped one.
      if (play && !player.playing) unawaited(player.play());
    } finally {
      _atBoundary = false;
    }
  }

  // --- Playback --------------------------------------------------------------

  /// Toggle for [range]; an unloaded one is loaded first.
  Future<void> _togglePlayRange(LessonState current, SegmentRange range) async {
    // A new action cancels a running countdown and the pause between repeats.
    final token = ++_actionToken;
    if (current.activeRange != range) {
      await _start(current, range, token, loop: _loopEnabled);
      return;
    }
    await _toggleActive(current, token);
  }

  /// Play/stop toggle for a segment.
  Future<void> togglePlay(int index) async {
    final current = state.value;
    if (current == null) return;
    await _togglePlayRange(current, SegmentRange.single(index));
  }

  /// Toggle for the selected range.
  Future<void> togglePlaySelection() async {
    final current = state.value;
    final selection = current?.selection;
    if (current == null || selection == null) return;
    await _togglePlayRange(current, selection);
  }

  /// Space plays the picked range, otherwise what the player shows.
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

  /// Toggle for whatever the player shows.
  Future<void> togglePlayCurrent() async {
    final current = state.value;
    if (current == null) return;
    await _togglePlayRange(current, current.playerRange);
  }

  /// Moves to a single segment and drops the pinned range.
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

  /// Starts or stops whatever is already loaded into the player.
  Future<void> _toggleActive(LessonState current, int token) async {
    final range = current.activeRange;
    if (current.isPlaying) {
      // Stop rather than pause: the next start begins at the segment start.
      _setCountdown(null);
      if (range != null) await _rewindTo(current, range, play: false);
      return;
    }
    _atBoundary = false;
    _passCount = 0;
    if (!await _runCountdown(token)) return;
    // The last segment may end with the file — restart the range.
    if (range != null && _player.processingState == ProcessingState.completed) {
      await _rewindTo(current, range, play: true);
      return;
    }
    unawaited(_player.play());
  }

  /// Loads a range and starts it from the beginning.
  Future<void> _start(
    LessonState current,
    SegmentRange range,
    int token, {
    required bool loop,
  }) async {
    final segments = current.lesson.segments;
    if (range.end >= segments.length) return;
    final player = _player;
    await _ensureSource(current.lesson.audioPath);
    _activeLooped = loop;
    _passCount = 0;
    // Mute the guard while switching: seek lands on the end of the previous
    // segment and the guard would take it for the range end.
    _atBoundary = true;
    await player.seek(Duration(milliseconds: segments[range.start].startMs));
    await player.setSpeed(_speed);
    // During the countdown the range is shown but not playing yet.
    final showCountdown = _settings.countdownEnabled;
    state = AsyncValue.data(
      current.copyWith(activeRange: range, isPlaying: !showCountdown),
    );
    // The range is loaded — the guard watches its end again.
    _atBoundary = false;
    if (showCountdown) {
      if (!await _runCountdown(token)) return;
      final ready = state.value;
      if (ready == null) return;
      state = AsyncValue.data(ready.copyWith(isPlaying: true));
    }
    // play() completes only at the end of the track — do not await it.
    unawaited(player.play());
  }

  /// Shows the 3-2-1 countdown before the start; `false` when another action
  /// began meanwhile.
  Future<bool> _runCountdown(int token) async {
    if (!_settings.countdownEnabled) return true;
    for (var n = 3; n >= 1; n--) {
      _setCountdown(n);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (token != _actionToken) {
        _setCountdown(null);
        return false;
      }
    }
    _setCountdown(null);
    return true;
  }

  void _setCountdown(int? value) {
    final current = state.value;
    if (current == null || current.countdown == value) return;
    state = AsyncValue.data(
      current.copyWith(countdown: value, clearCountdown: value == null),
    );
  }

  /// Loads the whole lesson file — once per lesson.
  Future<void> _ensureSource(String audioPath) async {
    if (_loadedPath == audioPath) return;
    final player = _player;
    await player.stop();
    await player.setAudioSource(AudioSource.file(audioPath));
    // The cycle is a seek to the range start — LoopMode is not needed.
    await player.setLoopMode(LoopMode.off);
    _loadedPath = audioPath;
  }

  /// Player repeat toggle shared by a segment and a pinned range.
  void toggleLoop() {
    final current = state.value;
    if (current == null) return;
    _loopEnabled = !_loopEnabled;
    if (current.activeRange != null) _activeLooped = _loopEnabled;
    state = AsyncValue.data(current.copyWith(isLooped: _loopEnabled));
  }

  /// Speed for the whole lesson; applied on the fly.
  Future<void> setSpeed(double speed) async {
    final current = state.value;
    if (current == null || current.speed == speed) return;
    _speed = speed;
    state = AsyncValue.data(current.copyWith(speed: speed));
    await _player.setSpeed(speed);
  }

  // --- Media session (headset buttons) ---------------------------------------

  /// Stops a sounding player; does nothing when it is idle.
  Future<void> stopPlayback() async {
    final current = state.value;
    if (current == null || !current.isPlaying) return;
    final range = current.activeRange;
    if (range == null) return;
    // Cancel a running countdown and the pause between repeats.
    _actionToken++;
    _setCountdown(null);
    await _rewindTo(current, range, play: false);
  }

  /// Headset single click — toggles what the player shows.
  @override
  void remoteToggle() => unawaited(togglePlayCurrent());

  /// Headset double click — the next segment.
  @override
  void remoteNext() => unawaited(next());

  /// Headset triple click — the previous segment.
  @override
  void remotePrevious() => unawaited(previous());

  @override
  void remoteStop() => unawaited(stopPlayback());

  // --- Segment selection -----------------------------------------------------

  /// Enters segment selection mode.
  void startSelecting() {
    final current = state.value;
    if (current == null || current.isSelecting) return;
    state = AsyncValue.data(current.copyWith(isSelecting: true));
  }

  /// Leaves selection mode and clears the selection.
  void stopSelecting() {
    final current = state.value;
    if (current == null || !current.isSelecting) return;
    _selectionAnchor = null;
    state = AsyncValue.data(
      current.copyWith(isSelecting: false, clearSelection: true),
    );
  }

  /// Loads the selection into the player: a range gets pinned, a single
  /// segment becomes current.
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

  /// Ends selection keeping the loaded range; `true` when something was picked.
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

  /// Tap in selection mode: the first sets the anchor, the second the end.
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

  /// Walks segments with arrows; with [extend] grows the selection.
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
    // The cursor follows the moving end while the player loads the whole range.
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
    // Moving to a single segment drops the pinned range.
    state = AsyncValue.data(
      current.copyWith(focusedIndex: index, clearCommittedRange: true),
    );
  }

  /// Re-reads the lesson after editing, clearing selection and position.
  Future<void> reload() async {
    await _player.stop();
    _loopEnabled = false;
    _selectionAnchor = null;
    _activeLooped = false;
    _atBoundary = false;
    _passCount = 0;
    // Cancel a running countdown and the pause between repeats.
    _actionToken++;
    // The file could be replaced together with the split.
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
