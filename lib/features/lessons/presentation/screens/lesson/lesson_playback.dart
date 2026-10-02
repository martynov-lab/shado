import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../../../../core/audio/lesson_remote_control.dart';
import '../../../../../core/audio/shadowing_audio_handler.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../progress/domain/services/progress_reporter.dart';
import '../../../../settings/domain/entities/playback_settings.dart';
import '../../../../settings/domain/services/completion_threshold_service.dart';
import '../../../../settings/domain/services/playback_settings_service.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/segment_range.dart';
import 'lesson_state.dart';

/// Position polling period while watching for the range end.
const _positionTick = Duration(milliseconds: 10);

/// Plays one lesson: segments and ranges, repeats, the countdown and speed.
/// Counts listened time and repeats for progress and answers the headset
/// buttons. Call [open] with the loaded lesson and [dispose] when the screen
/// closes; changes come through [onChanged] and [onPosition].
class LessonPlayback implements LessonRemoteControl {
  LessonPlayback({
    required this.lessonId,
    required AudioPlayer player,
    required ProgressReporter reporter,
    required PlaybackSettingsService settings,
    required CompletionThresholdService threshold,
    required this.onChanged,
    required this.onPosition,
    ShadowingAudioHandler? audioHandler,
  }) : _player = player,
       _reporter = reporter,
       _settingsService = settings,
       _threshold = threshold,
       _audioHandler = audioHandler;

  final String lessonId;
  final AudioPlayer _player;
  final ProgressReporter _reporter;
  final PlaybackSettingsService _settingsService;
  final CompletionThresholdService _threshold;
  final ShadowingAudioHandler? _audioHandler;

  /// Called with every new screen state.
  final void Function(LessonState state) onChanged;

  /// Called with the playback position in milliseconds, ~25 times a second.
  final void Function(int positionMs) onPosition;

  LessonState? _current;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _flushTimer;
  bool _isStarted = false;

  /// Playback speed; survives reloading the lesson.
  double? _speed;

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

  PlaybackSettings get _settings => _settingsService.settings;

  /// Shows [lesson] from the start. The first call also starts listening to
  /// the player, the headset and the progress timer.
  Future<void> open(Lesson lesson) async {
    final settings = await _settingsService.load();
    _speed ??= settings.defaultSpeed;
    if (!_isStarted) _startListening();
    _emit(LessonState(lesson: lesson, speed: _speed!, isLooped: _loopEnabled));
  }

  /// Stops and forgets the selection and position before the lesson is read
  /// again, for example after editing.
  Future<void> reset() async {
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
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _flushTimer?.cancel();
    _audioHandler?.detach(this);
    await _flushOnLeave();
    await _player.dispose();
  }

  void _startListening() {
    _isStarted = true;
    _subscriptions
      ..add(_player.playerStateStream.listen(_onPlayerState))
      // Equal min and max keep the period exactly one tick.
      ..add(
        _player
            .createPositionStream(
              steps: 1,
              minPeriod: _positionTick,
              maxPeriod: _positionTick,
            )
            .listen(_onPosition),
      );
    _audioHandler?.attach(this);
    _threshold.load().ignore();
    _flushTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _reporter.flush(lessonId: lessonId),
    );
  }

  void _emit(LessonState state) {
    _current = state;
    onChanged(state);
    _audioHandler?.setNowPlaying(
      id: lessonId,
      title: state.lesson.title,
      album: state.playerText,
      duration: Duration(milliseconds: state.playerEndMs - state.playerStartMs),
      playing: state.isPlaying,
    );
  }

  void _onPlayerState(PlayerState playerState) {
    final current = _current;
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
      _emit(current.copyWith(isPlaying: isPlaying));
    }
  }

  /// Range end guard: the whole file is loaded, so the boundary is watched
  /// by position.
  void _onPosition(Duration position) {
    _pushWavePosition(position.inMilliseconds);
    final current = _current;
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
    final latest = _current ?? current;
    await _rewindTo(latest, range, play: true);
  }

  /// Pushes the position to the track at most ~25 times per second.
  void _pushWavePosition(int ms) {
    if ((ms - _lastWaveMs).abs() < 40) return;
    _lastWaveMs = ms;
    onPosition(ms);
  }

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

  /// Sends `completed` once the lesson is done.
  void _maybeReportCompletion() {
    final current = _current;
    if (current == null) return;
    // The threshold has not loaded yet — check on the next pass.
    final target = _threshold.reps;
    if (target == null) return;
    unawaited(
      _reporter.reportCompletedIfDone(
        lessonId: lessonId,
        segmentCount: current.lesson.segmentCount,
        completionReps: target,
      ),
    );
  }

  Future<void> _flushOnLeave() async {
    final started = _playStartedAt;
    _playStartedAt = null;
    if (started != null) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (ms > 0) await _reporter.addListened(ms);
    }
    await _reporter.flush(lessonId: lessonId);
  }

  /// Seeks to the range start and, when [play], begins a lap.
  Future<void> _rewindTo(
    LessonState current,
    SegmentRange range, {
    required bool play,
  }) async {
    final segments = current.lesson.segments;
    try {
      if (range.start >= segments.length) return;
      if (!play) await _player.pause();
      await _player.seek(Duration(milliseconds: segments[range.start].startMs));
      // A finished player stays "playing" — only resume a stopped one.
      if (play && !_player.playing) unawaited(_player.play());
    } finally {
      _atBoundary = false;
    }
  }

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
    final current = _current;
    if (current == null) return;
    await _togglePlayRange(current, SegmentRange.single(index));
  }

  /// Toggle for the selected range.
  Future<void> togglePlaySelection() async {
    final current = _current;
    final selection = current?.selection;
    if (current == null || selection == null) return;
    await _togglePlayRange(current, selection);
  }

  /// Space plays the picked range, otherwise what the player shows.
  Future<void> togglePlayFocused() async {
    final current = _current;
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
    final current = _current;
    if (current == null) return;
    await _togglePlayRange(current, current.playerRange);
  }

  /// Moves to a single segment and drops the pinned range.
  Future<void> goToSegment(int index) async {
    final current = _current;
    if (current == null) return;
    if (index < 0 || index >= current.lesson.segmentCount) return;
    if (index == current.currentIndex && current.committedRange == null) return;
    final wasPlaying = current.isPlayerPlaying;
    setFocus(index);
    if (wasPlaying) await togglePlay(index);
  }

  Future<void> next() => goToSegment((_current?.playerRange.end ?? 0) + 1);

  Future<void> previous() =>
      goToSegment((_current?.playerRange.start ?? 0) - 1);

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
    await _ensureSource(current.lesson.audioPath);
    _activeLooped = loop;
    _passCount = 0;
    // Mute the guard while switching: seek lands on the end of the previous
    // segment and the guard would take it for the range end.
    _atBoundary = true;
    await _player.seek(Duration(milliseconds: segments[range.start].startMs));
    await _player.setSpeed(current.speed);
    // During the countdown the range is shown but not playing yet.
    final showCountdown = _settings.countdownEnabled;
    _emit(current.copyWith(activeRange: range, isPlaying: !showCountdown));
    // The range is loaded — the guard watches its end again.
    _atBoundary = false;
    if (showCountdown) {
      if (!await _runCountdown(token)) return;
      final ready = _current;
      if (ready == null) return;
      _emit(ready.copyWith(isPlaying: true));
    }
    // play() completes only at the end of the track — do not await it.
    unawaited(_player.play());
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
    final current = _current;
    if (current == null || current.countdown == value) return;
    _emit(current.copyWith(countdown: value, clearCountdown: value == null));
  }

  /// Loads the whole lesson file — once per lesson.
  Future<void> _ensureSource(String audioPath) async {
    if (_loadedPath == audioPath) return;
    await _player.stop();
    await _player.setAudioSource(AudioSource.file(audioPath));
    // The cycle is a seek to the range start — LoopMode is not needed.
    await _player.setLoopMode(LoopMode.off);
    _loadedPath = audioPath;
  }

  /// Player repeat toggle shared by a segment and a pinned range.
  void toggleLoop() {
    final current = _current;
    if (current == null) return;
    _loopEnabled = !_loopEnabled;
    if (current.activeRange != null) _activeLooped = _loopEnabled;
    _emit(current.copyWith(isLooped: _loopEnabled));
  }

  /// Speed for the whole lesson; applied on the fly.
  Future<void> setSpeed(double speed) async {
    final current = _current;
    if (current == null || current.speed == speed) return;
    _speed = speed;
    _emit(current.copyWith(speed: speed));
    await _player.setSpeed(speed);
  }

  /// Stops a sounding player; does nothing when it is idle.
  Future<void> stopPlayback() async {
    final current = _current;
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

  /// Enters segment selection mode.
  void startSelecting() {
    final current = _current;
    if (current == null || current.isSelecting) return;
    _emit(current.copyWith(isSelecting: true));
  }

  /// Leaves selection mode and clears the selection.
  void stopSelecting() {
    final current = _current;
    if (current == null || !current.isSelecting) return;
    _selectionAnchor = null;
    _emit(current.copyWith(isSelecting: false, clearSelection: true));
  }

  /// Loads the selection into the player: a range gets pinned, a single
  /// segment becomes current.
  void _applySelection(LessonState current, SegmentRange? selection) {
    final isRange = selection != null && !selection.isSingle;
    _emit(
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
    final current = _current;
    if (current == null) return false;
    final hadSelection =
        current.selection != null || current.committedRange != null;
    _selectionAnchor = null;
    _emit(current.copyWith(isSelecting: false, clearSelection: true));
    return hadSelection;
  }

  /// Tap in selection mode: the first sets the anchor, the second the end.
  void toggleSelection(int index) {
    final current = _current;
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
    final current = _current;
    if (current == null) return;
    final count = current.lesson.segmentCount;
    if (count == 0) return;
    _selectionAnchor = 0;
    _applySelection(current, SegmentRange(0, count - 1));
  }

  void clearSelection() {
    final current = _current;
    if (current == null || current.selection == null) return;
    _selectionAnchor = null;
    _applySelection(current, null);
  }

  /// Walks segments with arrows; with [extend] grows the selection.
  void moveFocus(int delta, {bool extend = false}) {
    final current = _current;
    if (current == null) return;
    final count = current.lesson.segmentCount;
    if (count == 0) return;
    final from = current.focusedIndex ?? (delta > 0 ? -1 : count);
    final index = (from + delta).clamp(0, count - 1);
    if (!extend) {
      _emit(current.copyWith(focusedIndex: index, clearCommittedRange: true));
      return;
    }
    final anchor = _selectionAnchor ?? current.focusedIndex ?? index;
    _selectionAnchor = anchor;
    final selection = SegmentRange.between(anchor, index);
    // The cursor follows the moving end while the player loads the whole range.
    final isRange = !selection.isSingle;
    _emit(
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
    final current = _current;
    if (current == null) return;
    if (current.focusedIndex == index && current.committedRange == null) return;
    // Moving to a single segment drops the pinned range.
    _emit(current.copyWith(focusedIndex: index, clearCommittedRange: true));
  }
}
