import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/audio_trim.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/segment_boundaries.dart';
import '../../../domain/usecases/create_lesson.dart';
import '../../widgets/segment_splitter/segment_boundary_math.dart' as marks;
import 'edit_lesson_state.dart';

/// Edits one lesson: title, text split, boundaries, trim and privacy, with a
/// player for the whole file. Every change keeps the boundaries in step with
/// the text. Call [dispose] when the screen closes.
class LessonEditor {
  LessonEditor(Lesson lesson, this._player)
    : _state = ValueNotifier(
        EditLessonState(
          lesson: lesson,
          title: lesson.title,
          text: initialText(lesson),
          boundaries: lesson.boundaries,
          trim: lesson.trim,
          isPublic: lesson.isPublic,
          // The lesson starts where the trimmed head ends.
          playheadMs: lesson.trim.startMs,
        ),
      ) {
    _subscriptions
      ..add(_player.playerStateStream.listen(_onPlayerState))
      ..add(_player.positionStream.listen(_onPosition));
  }

  final AudioPlayer _player;
  final ValueNotifier<EditLessonState> _state;
  final ValueNotifier<int> _positionMs = ValueNotifier(0);
  final List<StreamSubscription<Object?>> _subscriptions = [];

  ValueListenable<EditLessonState> get state => _state;

  /// Where the playhead is: the player position while it plays.
  ValueListenable<int> get positionMs => _positionMs;

  int get playheadMs =>
      _state.value.isPlaying ? _positionMs.value : _state.value.playheadMs;

  /// Lesson text as one string with segment delimiters.
  static String initialText(Lesson lesson) => lesson.segments
      .map((segment) => segment.text)
      .join(' $kSegmentDelimiter ');

  void setTitle(String title) =>
      _state.value = _state.value.copyWith(title: title);

  /// Changes the text and refits the markers.
  void setText(String text) {
    final next = _state.value.copyWith(text: text);
    _state.value = next.copyWith(boundaries: _resizeBoundaries(next));
  }

  void setBoundaries(List<int> boundaries) =>
      _state.value = _state.value.copyWith(boundaries: boundaries);

  void setMarkerAtPlayhead(bool enabled) =>
      _state.value = _state.value.copyWith(markerAtPlayhead: enabled);

  /// Puts marker [ordinal] into the text and its boundary on the waveform:
  /// under the playhead when "marker at playhead" is on, otherwise right of
  /// the previous one.
  void insertMarker(String text, int ordinal) {
    final current = _state.value;
    final boundaries = current.boundaries;
    final next = current.copyWith(text: text);
    // The layout lags behind the text — lay it out again.
    if (boundaries.length != current.segmentCount + 1) {
      _state.value = next.copyWith(boundaries: _resizeBoundaries(next));
      return;
    }
    // The marker is placed inside the range that is kept.
    final span = AudioTrim(startMs: boundaries.first, endMs: boundaries.last);
    final ms = current.markerAtPlayhead
        ? playheadMs
        : SegmentBoundaries.afterPrevious(boundaries, ordinal);
    _state.value = next.copyWith(
      boundaries: SegmentBoundaries.insertAt(boundaries, ordinal, ms, span),
    );
  }

  /// Removes marker [ordinal] from the text and its boundary from the wave.
  void removeMarker(int ordinal) {
    final current = _state.value;
    final indices = marks.markerIndices(current.text);
    if (ordinal < 1 || ordinal > indices.length) return;
    final nextText = marks.removeMarker(current.text, indices[ordinal - 1]);
    final boundaries = current.boundaries;
    final inSync = boundaries.length == current.segmentCount + 1;
    final nextBoundaries = inSync && ordinal < boundaries.length - 1
        ? ([...boundaries]..removeAt(ordinal))
        : SegmentBoundaries.resize(
            boundaries,
            CreateLesson.splitIntoSegments(nextText).length,
            current.trim,
          );
    _state.value = current.copyWith(text: nextText, boundaries: nextBoundaries);
  }

  void setPrivate(bool isPrivate) =>
      _state.value = _state.value.copyWith(isPublic: !isPrivate);

  /// Enters trim mode and brings the whole file back into the window.
  void startTrim() {
    final current = _state.value;
    if (current.isTrimming) return;
    _state.value = current.copyWith(pendingTrim: current.trim);
  }

  void updateTrim(AudioTrim trim) {
    final current = _state.value;
    if (!current.isTrimming) return;
    _state.value = current.copyWith(pendingTrim: trim);
  }

  Future<void> cancelTrim() async {
    final current = _state.value;
    if (!current.isTrimming) return;
    _state.value = current.copyWith(clearPendingTrim: true);
    // The playhead could have moved outside the lesson.
    await seek(current.trim.clampMs(current.playheadMs));
  }

  /// Applies the trim, moving segment markers inside the new range.
  Future<void> applyTrim() async {
    final current = _state.value;
    final pending = current.pendingTrim;
    if (pending == null) return;
    _state.value = current.copyWith(
      trim: pending,
      clearPendingTrim: true,
      // Trimming keeps the segment count; only the markers move.
      boundaries: current.boundaries.length == current.segmentCount + 1
          ? SegmentBoundaries.refit(current.boundaries, pending)
          : SegmentBoundaries.resize(
              current.boundaries,
              current.segmentCount,
              pending,
            ),
    );
    await seek(pending.clampMs(current.playheadMs));
  }

  /// Moves the playhead without interrupting playback.
  Future<void> seek(int positionMs) async {
    final current = _state.value;
    final clamped = current.isTrimming
        ? positionMs.clamp(0, current.lesson.durationMs)
        : current.trim.clampMs(positionMs);
    _state.value = current.copyWith(playheadMs: clamped);
    if (_player.audioSource != null) {
      await _player.seek(Duration(milliseconds: clamped));
    }
  }

  /// Play/pause toggle; starts from the playhead.
  Future<void> togglePlay() async {
    final current = _state.value;
    // Trust our own state: a finished player keeps `playing` set.
    if (current.isPlaying) {
      await _player.pause();
      await seek(_player.position.inMilliseconds);
      return;
    }
    // The source is set once for the whole screen.
    if (_player.audioSource == null) {
      await _player.setFilePath(current.lesson.audioPath);
    }
    // There is nothing to play at the very end — restart the track.
    await seek(
      !current.isTrimming && current.playheadMs >= current.trim.endMs
          ? current.trim.startMs
          : current.playheadMs,
    );
    // play() completes only at the end of the track — do not await it.
    unawaited(_player.play());
  }

  void setSaving(bool saving) =>
      _state.value = _state.value.copyWith(isSaving: saving);

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _state.dispose();
    _positionMs.dispose();
    await _player.dispose();
  }

  /// Refits the layout to the text and the trim.
  List<int> _resizeBoundaries(EditLessonState form) => form.segmentCount == 0
      ? form.boundaries
      : SegmentBoundaries.resize(form.boundaries, form.segmentCount, form.trim);

  /// Follows the player and stops at the end of the trimmed range.
  void _onPosition(Duration position) {
    _positionMs.value = position.inMilliseconds;
    final current = _state.value;
    if (!current.isPlaying || current.isTrimming) return;
    if (position.inMilliseconds < current.trim.endMs) return;
    unawaited(_player.pause());
    unawaited(seek(current.trim.endMs));
  }

  void _onPlayerState(PlayerState playerState) {
    final current = _state.value;
    final finished = playerState.processingState == ProcessingState.completed;
    if (finished && playerState.playing) {
      // A finished player stays "playing" — clear that ourselves.
      unawaited(_player.pause());
    }
    final isPlaying = playerState.playing && !finished;
    if (isPlaying == current.isPlaying) return;
    _state.value = current.copyWith(isPlaying: isPlaying);
  }
}
