import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Plays a range of a local file and reports when it ends. The end is
/// watched by position, as the desktop backends ignore clipping.
class ClipPlayer {
  ClipPlayer(this._player) {
    _subscriptions
      ..add(
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) _finish();
        }),
      )
      ..add(
        _player
            .createPositionStream(
              steps: 1,
              minPeriod: _tick,
              maxPeriod: _tick,
            )
            .listen(_onPosition),
      );
  }

  static const Duration _tick = Duration(milliseconds: 20);

  final AudioPlayer _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final StreamController<void> _completions = StreamController.broadcast();

  String? _loadedPath;
  int? _endMs;
  bool _active = false;

  /// Fires each time a clip plays to its end.
  Stream<void> get completions => _completions.stream;

  /// Whether audio is playing now.
  Stream<bool> get playingChanges => _player.playingStream;

  bool get isPlaying => _player.playing;

  /// Plays [path] from [startMs] to [endMs]; without [endMs] to the file end.
  Future<void> play(String path, {int startMs = 0, int? endMs}) async {
    _active = false;
    if (_loadedPath != path) {
      await _player.setFilePath(path);
      _loadedPath = path;
    }
    _endMs = endMs;
    await _player.seek(Duration(milliseconds: startMs));
    _active = true;
    unawaited(_player.play());
  }

  Future<void> stop() async {
    _active = false;
    await _player.pause();
  }

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _completions.close();
    await _player.dispose();
  }

  void _onPosition(Duration position) {
    final end = _endMs;
    if (end != null && position.inMilliseconds >= end) _finish();
  }

  void _finish() {
    if (!_active) return;
    _active = false;
    unawaited(_player.pause());
    _completions.add(null);
  }
}
