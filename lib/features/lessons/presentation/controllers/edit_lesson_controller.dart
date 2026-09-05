import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import '../widgets/segment_splitter/segment_boundary_math.dart' as marks;
import 'lesson_providers.dart';
import 'lessons_controller.dart';
import 'library_controller.dart';

/// Editor screen player; it plays the whole file, not a cut range.
final editLessonPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, lessonId) {
      final player = AudioPlayer();
      ref.onDispose(player.dispose);
      return player;
    });

/// Playback position on the editor screen.
final editPlaybackPositionProvider = StreamProvider.autoDispose
    .family<Duration, String>((ref, lessonId) {
      return ref.watch(editLessonPlayerProvider(lessonId)).positionStream;
    });

/// State of the lesson editor screen.
class EditLessonState {
  const EditLessonState({
    required this.lesson,
    required this.title,
    required this.text,
    required this.boundaries,
    required this.trim,
    required this.isPublic,
    this.pendingTrim,
    this.markerAtPlayhead = false,
    this.playheadMs = 0,
    this.isPlaying = false,
    this.isSaving = false,
  });

  final Lesson lesson;
  final String title;
  final String text;
  final List<int> boundaries;

  /// Lesson visibility; only the owner controls the switch.
  final bool isPublic;

  /// File range left by trimming.
  final AudioTrim trim;

  /// Range under the trim handles; `null` when trimming is off.
  final AudioTrim? pendingTrim;

  /// Whether a new marker lands at the playhead position.
  final bool markerAtPlayhead;

  /// Playhead position in file milliseconds.
  final int playheadMs;

  final bool isPlaying;
  final bool isSaving;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  bool get isTrimming => pendingTrim != null;

  /// What the waveform window shows: the whole file when trimming, else [trim].
  AudioTrim get view => isTrimming ? AudioTrim.full(lesson.durationMs) : trim;

  bool get canSave =>
      !isSaving &&
      // An unfinished trim must be applied or cancelled first.
      !isTrimming &&
      title.trim().isNotEmpty &&
      segmentCount > 0;

  EditLessonState copyWith({
    String? title,
    String? text,
    List<int>? boundaries,
    AudioTrim? trim,
    AudioTrim? pendingTrim,
    bool clearPendingTrim = false,
    bool? isPublic,
    bool? markerAtPlayhead,
    int? playheadMs,
    bool? isPlaying,
    bool? isSaving,
  }) {
    return EditLessonState(
      lesson: lesson,
      title: title ?? this.title,
      text: text ?? this.text,
      boundaries: boundaries ?? this.boundaries,
      trim: trim ?? this.trim,
      pendingTrim: clearPendingTrim ? null : (pendingTrim ?? this.pendingTrim),
      isPublic: isPublic ?? this.isPublic,
      markerAtPlayhead: markerAtPlayhead ?? this.markerAtPlayhead,
      playheadMs: playheadMs ?? this.playheadMs,
      isPlaying: isPlaying ?? this.isPlaying,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Lesson editing: text split, segment boundaries and audio preview.
class EditLessonController extends AsyncNotifier<EditLessonState> {
  EditLessonController(this.lessonId);

  final String lessonId;

  AudioPlayer get _player => ref.read(editLessonPlayerProvider(lessonId));

  @override
  Future<EditLessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    // watch: the player is autoDispose and lives with the notifier.
    final player = ref.watch(editLessonPlayerProvider(lessonId));
    final stateSubscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(stateSubscription.cancel);
    final positionSubscription = player.positionStream.listen(_onPosition);
    ref.onDispose(positionSubscription.cancel);
    return EditLessonState(
      lesson: lesson,
      title: lesson.title,
      text: initialText(lesson),
      boundaries: lesson.boundaries,
      trim: lesson.trim,
      isPublic: lesson.isPublic,
      // The lesson starts where the trimmed head ends.
      playheadMs: lesson.trim.startMs,
    );
  }

  /// Stops playback at the end of the trimmed range.
  void _onPosition(Duration position) {
    final current = state.value;
    if (current == null || !current.isPlaying || current.isTrimming) return;
    if (position.inMilliseconds < current.trim.endMs) return;
    unawaited(_player.pause());
    unawaited(seek(current.trim.endMs));
  }

  void _onPlayerState(PlayerState playerState) {
    final current = state.value;
    if (current == null) return;
    final finished = playerState.processingState == ProcessingState.completed;
    if (finished && playerState.playing) {
      // A finished player stays "playing" — clear that ourselves.
      unawaited(_player.pause());
    }
    final isPlaying = playerState.playing && !finished;
    if (isPlaying == current.isPlaying) return;
    state = AsyncValue.data(current.copyWith(isPlaying: isPlaying));
  }

  /// Lesson text as one string with segment delimiters.
  static String initialText(Lesson lesson) => lesson.segments
      .map((segment) => segment.text)
      .join(' $kSegmentDelimiter ');

  void setTitle(String title) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(title: title));
  }

  /// Changes the text and refits the markers.
  void setText(String text) {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(text: text);
    state = AsyncValue.data(
      next.copyWith(boundaries: _resizeBoundaries(next)),
    );
  }

  void setBoundaries(List<int> boundaries) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(boundaries: boundaries));
  }

  /// The marker-at-playhead checkbox next to the play button.
  void setMarkerAtPlayhead(bool value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(markerAtPlayhead: value));
  }

  /// Puts marker [ordinal] into the text and its boundary on the waveform.
  void insertMarker(String text, int ordinal, int playheadMs) {
    final current = state.value;
    if (current == null) return;
    final boundaries = current.boundaries;
    final next = current.copyWith(text: text);
    // The layout lags behind the text — lay it out again.
    if (boundaries.length != current.segmentCount + 1) {
      state = AsyncValue.data(next.copyWith(boundaries: _resizeBoundaries(next)));
      return;
    }
    // The marker is placed inside the range that is kept.
    final span = AudioTrim(startMs: boundaries.first, endMs: boundaries.last);
    final ms = current.markerAtPlayhead
        ? playheadMs
        : SegmentBoundaries.afterPrevious(boundaries, ordinal);
    state = AsyncValue.data(
      next.copyWith(
        boundaries: SegmentBoundaries.insertAt(boundaries, ordinal, ms, span),
      ),
    );
  }

  /// Refits the layout to the text and the trim.
  List<int> _resizeBoundaries(EditLessonState form) => form.segmentCount == 0
      ? form.boundaries
      : SegmentBoundaries.resize(form.boundaries, form.segmentCount, form.trim);

  /// Removes marker [ordinal] from the text and its boundary from the wave.
  void removeMarker(int ordinal) {
    final current = state.value;
    if (current == null) return;
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
    state = AsyncValue.data(
      current.copyWith(text: nextText, boundaries: nextBoundaries),
    );
  }

  /// The private lesson switch; available to the owner only.
  void setPrivate(bool isPrivate) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isPublic: !isPrivate));
  }

  // --- Trimming --------------------------------------------------------------

  /// Enters trim mode and brings the whole file back into the window.
  void startTrim() {
    final current = state.value;
    if (current == null || current.isTrimming) return;
    state = AsyncValue.data(current.copyWith(pendingTrim: current.trim));
  }

  void updateTrim(AudioTrim trim) {
    final current = state.value;
    if (current == null || !current.isTrimming) return;
    state = AsyncValue.data(current.copyWith(pendingTrim: trim));
  }

  Future<void> cancelTrim() async {
    final current = state.value;
    if (current == null || !current.isTrimming) return;
    state = AsyncValue.data(current.copyWith(clearPendingTrim: true));
    // The playhead could have moved outside the lesson.
    await seek(current.trim.clampMs(current.playheadMs));
  }

  /// Applies the trim, moving segment markers inside the new range.
  Future<void> applyTrim() async {
    final current = state.value;
    final pending = current?.pendingTrim;
    if (current == null || pending == null) return;
    state = AsyncValue.data(
      current.copyWith(
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
      ),
    );
    await seek(pending.clampMs(current.playheadMs));
  }

  /// Moves the playhead without interrupting playback.
  Future<void> seek(int positionMs) async {
    final current = state.value;
    if (current == null) return;
    final clamped = current.isTrimming
        ? positionMs.clamp(0, current.lesson.durationMs)
        : current.trim.clampMs(positionMs);
    state = AsyncValue.data(current.copyWith(playheadMs: clamped));
    if (_player.audioSource != null) {
      await _player.seek(Duration(milliseconds: clamped));
    }
  }

  /// Play/pause toggle; starts from the playhead.
  Future<void> togglePlay() async {
    final current = state.value;
    if (current == null) return;
    final player = _player;
    // Trust our own state: a finished player keeps `playing` set.
    if (current.isPlaying) {
      await player.pause();
      await seek(player.position.inMilliseconds);
      return;
    }
    // The source is set once for the whole screen.
    if (player.audioSource == null) {
      await player.setFilePath(current.lesson.audioPath);
    }
    // There is nothing to play at the very end — restart the track.
    await seek(
      !current.isTrimming && current.playheadMs >= current.trim.endMs
          ? current.trim.startMs
          : current.playheadMs,
    );
    // play() completes only at the end of the track — do not await it.
    unawaited(player.play());
  }

  /// Saves edits and refreshes the lesson list; version conflicts bubble up.
  Future<void> save() async {
    final current = state.value;
    if (current == null || !current.canSave) return;
    state = AsyncValue.data(current.copyWith(isSaving: true));
    try {
      await ref.read(updateLessonContentProvider)(
        lesson: current.lesson,
        title: current.title,
        rawText: current.text,
        boundaries: current.boundaries,
        trim: current.trim,
        isPublic: _isPublicForRole(current.isPublic),
      );
      ref.invalidate(lessonsControllerProvider);
      // The lesson card in the feed changed too.
      ref.invalidate(libraryControllerProvider);
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isSaving: false));
      rethrow;
    }
  }

  /// Visibility to send based on the author role; `null` lets the server pick.
  bool? _isPublicForRole(bool toggled) {
    final role = ref.read(authControllerProvider).user?.role;
    return switch (role) {
      UserRole.owner => toggled,
      UserRole.userPro => false,
      _ => null,
    };
  }
}

final editLessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<EditLessonController, EditLessonState, String>(
      EditLessonController.new,
    );
