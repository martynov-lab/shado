import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'add_lesson_controller.dart';

/// Lesson creation player; it plays the uploaded file in full.
final addLessonPlayerProvider = Provider.autoDispose<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Playback position on the lesson creation screen.
final addPlaybackPositionProvider = StreamProvider.autoDispose<Duration>(
  (ref) => ref.watch(addLessonPlayerProvider).positionStream,
);

/// Where the playhead is and whether audio is playing right now.
class AddLessonPlayback {
  const AddLessonPlayback({this.playheadMs = 0, this.isPlaying = false});

  /// Playhead position in file milliseconds.
  final int playheadMs;

  final bool isPlaying;

  AddLessonPlayback copyWith({int? playheadMs, bool? isPlaying}) =>
      AddLessonPlayback(
        playheadMs: playheadMs ?? this.playheadMs,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}

/// Audio preview on the lesson creation screen.
class AddLessonPlaybackController extends Notifier<AddLessonPlayback> {
  /// Path of the file loaded into the player.
  String? _loadedPath;

  AudioPlayer get _player => ref.read(addLessonPlayerProvider);

  AddLessonFormState get _form => ref.read(addLessonControllerProvider);

  @override
  AddLessonPlayback build() {
    // watch: the player is autoDispose and lives with the notifier.
    final player = ref.watch(addLessonPlayerProvider);
    final stateSubscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(stateSubscription.cancel);
    final positionSubscription = player.positionStream.listen(_onPosition);
    ref.onDispose(positionSubscription.cancel);

    // On a file change reset the playhead and the loaded source.
    ref.listen(addLessonControllerProvider.select((form) => form.audioId), (
      _,
      _,
    ) {
      _loadedPath = null;
      state = const AddLessonPlayback();
      unawaited(_stopQuietly());
    });

    return const AddLessonPlayback();
  }

  /// Stops the player, swallowing errors from an already closed one.
  Future<void> _stopQuietly() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Stops playback at the end of the trimmed range.
  void _onPosition(Duration position) {
    if (!state.isPlaying) return;
    final form = _form;
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
    final isPlaying = playerState.playing && !finished;
    if (isPlaying == state.isPlaying) return;
    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Moves the playhead without interrupting playback.
  Future<void> seek(int positionMs) async {
    final form = _form;
    if (form.durationMs <= 0) return;
    final clamped = form.isTrimming
        ? positionMs.clamp(0, form.durationMs)
        : form.trim.clampMs(positionMs);
    state = state.copyWith(playheadMs: clamped);
    if (_player.audioSource != null) {
      await _player.seek(Duration(milliseconds: clamped));
    }
  }

  /// Play/pause toggle; starts from the playhead.
  Future<void> togglePlay() async {
    final form = _form;
    final path = form.audioPath;
    // There is no file yet — nothing to play.
    if (path == null || form.durationMs <= 0) return;

    final player = _player;
    // Trust our own state: a finished player keeps `playing` set.
    if (state.isPlaying) {
      await player.pause();
      await seek(player.position.inMilliseconds);
      return;
    }
    if (_loadedPath != path) {
      await player.setFilePath(path);
      _loadedPath = path;
    }
    // There is nothing to play at the very end — restart the track.
    await seek(
      !form.isTrimming && state.playheadMs >= form.trim.endMs
          ? form.trim.startMs
          : state.playheadMs,
    );
    // play() completes only at the end of the track — do not await it.
    unawaited(player.play());
  }
}

final addLessonPlaybackProvider =
    NotifierProvider.autoDispose<
      AddLessonPlaybackController,
      AddLessonPlayback
    >(AddLessonPlaybackController.new);
