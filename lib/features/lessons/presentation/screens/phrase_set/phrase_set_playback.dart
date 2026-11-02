import 'dart:async';
import 'dart:math';

import '../../../../../core/audio/clip_player.dart';
import '../../../../../core/audio/lesson_remote_control.dart';
import '../../../../../core/audio/shadowing_audio_handler.dart';
import '../../../../progress/domain/services/progress_reporter.dart';
import '../../../../settings/domain/services/playback_settings_service.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/phrase_deck.dart';
import 'phrase_set_state.dart';
import 'phrase_study_mode.dart';

/// Plays a phrase set card by card: one phrase, a repeated phrase or the
/// whole deck round and round. Counts listened time and repeats for progress
/// and answers the headset buttons. Call [open] with the loaded set and
/// [dispose] when the screen closes; changes come through [onChanged].
class PhraseSetPlayback implements LessonRemoteControl {
  PhraseSetPlayback({
    required this.lessonId,
    required ClipPlayer player,
    required ProgressReporter reporter,
    required PlaybackSettingsService settings,
    required this.onChanged,
    ShadowingAudioHandler? audioHandler,
    Random? random,
  }) : _player = player,
       _reporter = reporter,
       _settings = settings,
       _audioHandler = audioHandler,
       _random = random ?? Random();

  final String lessonId;
  final ClipPlayer _player;
  final ProgressReporter _reporter;
  final PlaybackSettingsService _settings;
  final ShadowingAudioHandler? _audioHandler;
  final Random _random;

  /// Called with every new screen state.
  final void Function(PhraseSetState state) onChanged;

  PhraseSetState? _current;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _flushTimer;
  DateTime? _playStartedAt;

  /// Token of the last action; a newer one cancels a pending pause.
  int _actionToken = 0;

  PhraseSetState? get current => _current;

  Future<void> open(Lesson lesson) async {
    await _settings.load();
    final previous = _current;
    _emit(
      previous == null
          ? PhraseSetState.initial(lesson, speed: _settings.settings.defaultSpeed)
          : PhraseSetState.initial(
              lesson,
              speed: previous.speed,
            ).copyWith(mode: previous.mode),
    );
    await _player.setSpeed(_current!.speed);
    if (previous != null) return;
    _subscriptions
      ..add(_player.completions.listen((_) => unawaited(_onCompleted())))
      ..add(_player.playingChanges.listen(_onPlayingChanged));
    _audioHandler?.attach(this);
    _flushTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _reporter.flush(lessonId: lessonId),
    );
  }

  /// Plays the current phrase, or stops it.
  Future<void> togglePlay() async {
    final current = _current;
    if (current == null || current.isEmpty) return;
    if (current.isPlaying) {
      await _stop();
    } else {
      await _playCurrent();
    }
  }

  /// Moves [delta] cards along the deck; the card turns face down again.
  Future<void> step(int delta) async {
    final current = _current;
    if (current == null || current.isEmpty) return;
    final keepPlaying =
        current.isPlaying && current.mode == PhraseStudyMode.listen;
    await _stop();
    _emit(
      _current!.copyWith(
        position: current.positionAfter(delta),
        isFlipped: false,
      ),
    );
    if (keepPlaying) await _playCurrent();
  }

  /// Shows the phrase [phraseIndex]; outside the deck the whole set comes back.
  Future<void> goTo(int phraseIndex) async {
    var current = _current;
    if (current == null) return;
    if (!current.deck.contains(phraseIndex)) {
      current = _withDeck(current, _allIndices(current));
    }
    await _stop();
    _emit(
      current.copyWith(
        position: max(0, current.order.indexOf(phraseIndex)),
        isFlipped: false,
        isPlaying: false,
      ),
    );
  }

  /// Recall: shows the phrase and plays it.
  Future<void> flip() async {
    final current = _current;
    if (current == null || current.isEmpty || current.isFlipped) return;
    _emit(current.copyWith(isFlipped: true));
    await _playCurrent();
  }

  Future<void> setMode(PhraseStudyMode mode) async {
    final current = _current;
    if (current == null || current.mode == mode) return;
    await _stop();
    _emit(
      _current!.copyWith(mode: mode, isFlipped: false, isLooping: false),
    );
  }

  /// Listen: the deck plays round and round by itself.
  void toggleLooping() {
    final current = _current;
    if (current == null) return;
    _emit(current.copyWith(isLooping: !current.isLooping));
  }

  /// The current phrase repeats until switched off.
  void toggleRepeating() {
    final current = _current;
    if (current == null) return;
    _emit(current.copyWith(isRepeating: !current.isRepeating));
  }

  /// Shuffles the deck, or brings back the lesson order; the card on screen
  /// stays.
  void toggleShuffle() {
    final current = _current;
    if (current == null || current.isEmpty) return;
    final shuffled = !current.isShuffled;
    final order = shuffled ? shuffleDeck(current.deck, _random) : current.deck;
    _emit(
      current.copyWith(
        isShuffled: shuffled,
        order: order,
        position: max(0, order.indexOf(current.phraseIndex)),
      ),
    );
  }

  Future<void> setSpeed(double speed) async {
    final current = _current;
    if (current == null) return;
    await _player.setSpeed(speed);
    _emit(current.copyWith(speed: speed));
  }

  /// Opens deck selection with the current deck picked.
  void startSelecting() {
    final current = _current;
    if (current == null) return;
    _emit(
      current.copyWith(
        isSelecting: true,
        selection: current.isPartialDeck ? current.deck.toSet() : const {},
      ),
    );
  }

  void stopSelecting() {
    final current = _current;
    if (current == null) return;
    _emit(current.copyWith(isSelecting: false, selection: const {}));
  }

  void toggleSelected(int phraseIndex) {
    final current = _current;
    if (current == null) return;
    final selection = Set.of(current.selection);
    if (!selection.remove(phraseIndex)) selection.add(phraseIndex);
    _emit(current.copyWith(selection: selection));
  }

  /// Picks exactly [phraseIndices].
  void select(Iterable<int> phraseIndices) {
    final current = _current;
    if (current == null) return;
    _emit(current.copyWith(selection: phraseIndices.toSet()));
  }

  /// Makes the selection the deck; an empty one brings back the whole set.
  Future<void> applySelection() async {
    final current = _current;
    if (current == null) return;
    await _stop();
    final picked = current.selection.toList()..sort();
    _emit(
      _withDeck(
        _current!,
        picked.isEmpty ? _allIndices(current) : picked,
      ).copyWith(isSelecting: false, selection: const {}),
    );
  }

  /// Studies the whole set again.
  Future<void> resetDeck() async {
    final current = _current;
    if (current == null) return;
    await _stop();
    _emit(_withDeck(_current!, _allIndices(current)));
  }

  /// Sends the activity collected on the screen; call when it closes.
  Future<void> dispose() async {
    _actionToken++;
    _flushTimer?.cancel();
    _audioHandler?.detach(this);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _onPlayingChanged(false);
    await _reporter.flush(lessonId: lessonId);
    await _player.dispose();
  }

  @override
  void remoteToggle() => unawaited(togglePlay());

  @override
  void remoteNext() => unawaited(step(1));

  @override
  void remotePrevious() => unawaited(step(-1));

  @override
  void remoteStop() => unawaited(_stop());

  Future<void> _playCurrent() async {
    final current = _current;
    if (current == null || current.isEmpty) return;
    final phrase = current.current;
    if (phrase.audioPath.isEmpty) return;
    _actionToken++;
    _emit(current.copyWith(isPlaying: true));
    await _player.play(
      phrase.audioPath,
      startMs: phrase.playStartMs,
      endMs: phrase.endMs,
    );
  }

  Future<void> _stop() async {
    _actionToken++;
    await _player.stop();
    final current = _current;
    if (current != null && current.isPlaying) {
      _emit(current.copyWith(isPlaying: false));
    }
  }

  /// A phrase played to its end: repeat it, go on along the deck or stop.
  Future<void> _onCompleted() async {
    final current = _current;
    if (current == null) return;
    unawaited(_reporter.recordRepeats(1));
    final goesOn =
        current.isRepeating ||
        (current.isLooping && current.mode == PhraseStudyMode.listen);
    if (!goesOn) {
      _emit(current.copyWith(isPlaying: false));
      return;
    }
    final token = ++_actionToken;
    if (_settings.settings.pauseBetweenRepeats) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (token != _actionToken) return;
    }
    final latest = _current!;
    if (!latest.isRepeating) {
      _emit(latest.copyWith(position: latest.positionAfter(1)));
    }
    await _playCurrent();
  }

  /// Accumulates listened time across playback intervals.
  void _onPlayingChanged(bool playing) {
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

  PhraseSetState _withDeck(PhraseSetState state, List<int> deck) =>
      state.copyWith(
        deck: deck,
        order: state.isShuffled ? shuffleDeck(deck, _random) : deck,
        position: 0,
        isFlipped: false,
        isPlaying: false,
      );

  List<int> _allIndices(PhraseSetState state) => [
    for (var i = 0; i < state.lesson.phrases.length; i++) i,
  ];

  void _emit(PhraseSetState state) {
    _current = state;
    onChanged(state);
    if (state.isEmpty) return;
    final phrase = state.current;
    _audioHandler?.setNowPlaying(
      id: lessonId,
      title: state.lesson.title,
      album: phrase.text,
      duration: Duration(milliseconds: phrase.playEndMs - phrase.playStartMs),
      playing: state.isPlaying,
    );
  }
}
