import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'add_lesson_form.dart';

/// Plays the chosen file on the lesson creation screen: from the playhead to
/// the end of the trimmed range. A new file in [form] resets it.
class AddLessonPreview {
  AddLessonPreview(this._form, this._player) {
    _subscriptions
      ..add(_player.playerStateStream.listen(_onPlayerState))
      ..add(_player.positionStream.listen(_onPosition));
    _audioId = _form.value.audioId;
    _form.addListener(_onFormChanged);
  }

  final AddLessonForm _form;
  final AudioPlayer _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<int> _playheadMs = ValueNotifier(0);

  /// Path of the file loaded into the player.
  String? _loadedPath;
  String? _audioId;

  ValueListenable<bool> get isPlaying => _isPlaying;

  /// Playhead in file milliseconds; follows the player while it plays.
  ValueListenable<int> get playheadMs => _playheadMs;

  /// Moves the playhead without interrupting playback.
  Future<void> seek(int positionMs) async {
    final form = _form.value;
    if (form.durationMs <= 0) return;
    final clamped = form.isTrimming
        ? positionMs.clamp(0, form.durationMs)
        : form.trim.clampMs(positionMs);
    _playheadMs.value = clamped;
    if (_player.audioSource != null) {
      await _player.seek(Duration(milliseconds: clamped));
    }
  }

  /// Play/pause toggle; starts from the playhead.
  Future<void> togglePlay() async {
    final form = _form.value;
    final path = form.audioPath;
    // There is no file yet — nothing to play.
    if (path == null || form.durationMs <= 0) return;

    // Trust our own state: a finished player keeps `playing` set.
    if (_isPlaying.value) {
      await _player.pause();
      await seek(_player.position.inMilliseconds);
      return;
    }
    if (_loadedPath != path) {
      await _player.setFilePath(path);
      _loadedPath = path;
    }
    // There is nothing to play at the very end — restart the track.
    await seek(
      !form.isTrimming && _playheadMs.value >= form.trim.endMs
          ? form.trim.startMs
          : _playheadMs.value,
    );
    // play() completes only at the end of the track — do not await it.
    unawaited(_player.play());
  }

  Future<void> dispose() async {
    _form.removeListener(_onFormChanged);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _isPlaying.dispose();
    _playheadMs.dispose();
    await _player.dispose();
  }

  void _onFormChanged() {
    final audioId = _form.value.audioId;
    if (audioId == _audioId) return;
    _audioId = audioId;
    _loadedPath = null;
    _isPlaying.value = false;
    _playheadMs.value = 0;
    unawaited(_stopQuietly());
  }

  /// Stops the player, swallowing errors from an already closed one.
  Future<void> _stopQuietly() async {
    try {
      await _player.stop();
    } catch (_) {
      return;
    }
  }

  /// Follows the player and stops at the end of the trimmed range.
  void _onPosition(Duration position) {
    if (!_isPlaying.value) return;
    _playheadMs.value = position.inMilliseconds;
    final form = _form.value;
    if (form.isTrimming) return;
    if (position.inMilliseconds < form.trim.endMs) return;
    unawaited(_player.pause());
    unawaited(seek(form.trim.endMs));
  }

  void _onPlayerState(PlayerState playerState) {
    final finished = playerState.processingState == ProcessingState.completed;
    if (finished && playerState.playing) {
      // A finished player stays "playing" — clear that ourselves.
      unawaited(_player.pause());
    }
    _isPlaying.value = playerState.playing && !finished;
  }
}
