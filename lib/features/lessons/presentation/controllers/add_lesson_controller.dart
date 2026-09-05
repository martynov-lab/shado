import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/synthesize_tts.dart';
import '../widgets/segment_splitter/segment_boundary_math.dart' as marks;
import 'lesson_providers.dart';
import 'lessons_controller.dart';
import 'library_controller.dart';

/// State of the lesson creation form.
class AddLessonFormState {
  const AddLessonFormState({
    this.title = '',
    this.text = '',
    this.accent,
    this.level,
    this.topicId,
    this.audioId,
    this.audioPath,
    this.audioFileName,
    this.durationMs = 0,
    this.trim = const AudioTrim.full(0),
    this.pendingTrim,
    this.boundaries = const [],
    this.markerAtPlayhead = false,
    this.isPublic = true,
    this.isUploading = false,
    this.isSynthesizing = false,
    this.uploadProgress = 0,
    this.isSubmitting = false,
  });

  final String title;
  final String text;

  /// Accent and level are required; `null` means not chosen yet.
  final LessonAccent? accent;
  final LessonLevel? level;

  /// Topic from the directory; `null` lets the server pick the default.
  final String? topicId;

  /// Audio accepted by the server; `null` when nothing is uploaded yet.
  final String? audioId;

  /// Copy of the file in the app cache — the screen player uses it.
  final String? audioPath;

  final String? audioFileName;

  /// File duration; `0` when there is no file yet.
  final int durationMs;

  /// File range left by trimming.
  final AudioTrim trim;

  /// Range under the trim handles; `null` when trimming is off.
  final AudioTrim? pendingTrim;

  /// Segment layout on the waveform, `N + 1` values.
  final List<int> boundaries;

  /// Whether a new marker lands at the playhead position.
  final bool markerAtPlayhead;

  /// Lesson visibility; only the owner controls the switch.
  final bool isPublic;

  /// A file upload or an AI voice-over is running.
  final bool isUploading;

  /// An AI voice-over is running — it reports no percentage.
  final bool isSynthesizing;

  /// Uploaded share, `0..1`.
  final double uploadProgress;

  final bool isSubmitting;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  /// Whether there is anything to show on the waveform.
  bool get hasWaveform => audioId != null && durationMs > 0;

  bool get isTrimming => pendingTrim != null;

  /// What the waveform window shows: the whole file when trimming, else [trim].
  AudioTrim get view => isTrimming ? AudioTrim.full(durationMs) : trim;

  bool get canSubmit =>
      !isSubmitting &&
      !isUploading &&
      // An unfinished trim must be applied or cancelled first.
      !isTrimming &&
      title.trim().isNotEmpty &&
      segmentCount > 0 &&
      audioId != null &&
      // Without an accent and a level the server answers `422`.
      accent != null &&
      level != null;

  AddLessonFormState copyWith({
    String? title,
    String? text,
    LessonAccent? accent,
    LessonLevel? level,
    String? topicId,
    bool clearTopic = false,
    String? audioId,
    String? audioPath,
    bool clearAudio = false,
    String? audioFileName,
    int? durationMs,
    AudioTrim? trim,
    AudioTrim? pendingTrim,
    bool clearPendingTrim = false,
    List<int>? boundaries,
    bool? markerAtPlayhead,
    bool? isPublic,
    bool? isUploading,
    bool? isSynthesizing,
    double? uploadProgress,
    bool? isSubmitting,
  }) {
    return AddLessonFormState(
      title: title ?? this.title,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      level: level ?? this.level,
      topicId: clearTopic ? null : (topicId ?? this.topicId),
      audioId: clearAudio ? null : (audioId ?? this.audioId),
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      audioFileName: clearAudio ? null : (audioFileName ?? this.audioFileName),
      durationMs: durationMs ?? this.durationMs,
      trim: trim ?? this.trim,
      pendingTrim: clearPendingTrim ? null : (pendingTrim ?? this.pendingTrim),
      boundaries: boundaries ?? this.boundaries,
      markerAtPlayhead: markerAtPlayhead ?? this.markerAtPlayhead,
      isPublic: isPublic ?? this.isPublic,
      isUploading: isUploading ?? this.isUploading,
      isSynthesizing: isSynthesizing ?? this.isSynthesizing,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AddLessonController extends Notifier<AddLessonFormState> {
  /// Cancel token of the running upload or voice-over.
  CancelToken? _uploadCancel;

  @override
  AddLessonFormState build() {
    ref.onDispose(() => _uploadCancel?.cancel());
    return const AddLessonFormState();
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  /// Changes the text and refits the layout.
  void setText(String text) {
    final next = state.copyWith(text: text);
    state = next.copyWith(boundaries: _fitBoundaries(next));
  }

  void setBoundaries(List<int> boundaries) =>
      state = state.copyWith(boundaries: boundaries);

  /// The marker-at-playhead checkbox next to the play button.
  void setMarkerAtPlayhead(bool value) =>
      state = state.copyWith(markerAtPlayhead: value);

  /// Puts marker [ordinal] into the text and its boundary on the waveform.
  void insertMarker(String text, int ordinal, int playheadMs) {
    final boundaries = state.boundaries;
    final inSync = boundaries.length == state.segmentCount + 1;
    final next = state.copyWith(text: text);
    if (!inSync) {
      state = next.copyWith(boundaries: _fitBoundaries(next));
      return;
    }
    // The marker is placed inside the range that is kept.
    final span = AudioTrim(startMs: boundaries.first, endMs: boundaries.last);
    final ms = state.markerAtPlayhead
        ? playheadMs
        : SegmentBoundaries.afterPrevious(boundaries, ordinal);
    state = next.copyWith(
      boundaries: SegmentBoundaries.insertAt(boundaries, ordinal, ms, span),
    );
  }

  /// Removes marker [ordinal] from the text and its boundary from the wave.
  void removeMarker(int ordinal) {
    final indices = marks.markerIndices(state.text);
    if (ordinal < 1 || ordinal > indices.length) return;
    final nextText = marks.removeMarker(state.text, indices[ordinal - 1]);
    final boundaries = state.boundaries;
    final inSync = boundaries.length == state.segmentCount + 1;
    final next = state.copyWith(text: nextText);
    state = next.copyWith(
      boundaries: inSync && ordinal < boundaries.length - 1
          ? ([...boundaries]..removeAt(ordinal))
          : _fitBoundaries(next),
    );
  }

  void setAccent(LessonAccent? accent) =>
      state = state.copyWith(accent: accent);

  void setLevel(LessonLevel? level) => state = state.copyWith(level: level);

  /// The private lesson switch; available to the owner only.
  void setPrivate(bool isPrivate) =>
      state = state.copyWith(isPublic: !isPrivate);

  /// Picks a topic; `null` means no topic.
  void setTopic(String? topicId) => state = topicId == null
      ? state.copyWith(clearTopic: true)
      : state.copyWith(topicId: topicId);

  /// Drops the chosen topic when it is gone from the directory.
  void dropTopicUnless(Iterable<String> availableIds) {
    final selected = state.topicId;
    if (selected == null || availableIds.contains(selected)) return;
    state = state.copyWith(clearTopic: true);
  }

  void reset() => state = const AddLessonFormState();

  // --- Trimming --------------------------------------------------------------

  /// Enters trim mode and brings the whole file back into the window.
  void startTrim() {
    if (!state.hasWaveform || state.isTrimming) return;
    state = state.copyWith(pendingTrim: state.trim);
  }

  void updateTrim(AudioTrim trim) {
    if (!state.isTrimming) return;
    state = state.copyWith(pendingTrim: trim);
  }

  void cancelTrim() => state = state.copyWith(clearPendingTrim: true);

  /// Applies the trim, moving segment markers inside the new range.
  void applyTrim() {
    final pending = state.pendingTrim;
    if (pending == null) return;
    final next = state.copyWith(trim: pending, clearPendingTrim: true);
    state = next.copyWith(
      // Trimming keeps the segment count; only the markers move.
      boundaries: next.boundaries.length == next.segmentCount + 1
          ? SegmentBoundaries.refit(next.boundaries, next.trim)
          : _fitBoundaries(next),
    );
  }

  /// Refits the layout to the current text and trim.
  List<int> _fitBoundaries(AddLessonFormState form) {
    if (form.durationMs <= 0 || form.segmentCount == 0) return const [];
    return SegmentBoundaries.resize(
      form.boundaries,
      form.segmentCount,
      form.trim,
    );
  }

  // --- Audio -----------------------------------------------------------------

  /// Picks a file and uploads it; `true` when a file was chosen.
  Future<bool> pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedAudioExtensions,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return false;
    final name = result!.files.single.name;

    _uploadCancel?.cancel();
    final cancelToken = _uploadCancel = CancelToken();
    state = state.copyWith(
      clearAudio: true,
      audioFileName: name,
      durationMs: 0,
      trim: const AudioTrim.full(0),
      clearPendingTrim: true,
      boundaries: const [],
      isUploading: true,
      isSynthesizing: false,
      uploadProgress: 0,
    );

    try {
      final upload = await ref.read(uploadAudioProvider)(
        filePath: path,
        cancel: cancelToken,
        onProgress: (sent, total) {
          // Progress of a cancelled upload is no longer ours.
          if (_uploadCancel != cancelToken || total <= 0) return;
          state = state.copyWith(uploadProgress: sent / total);
        },
      );
      if (_uploadCancel != cancelToken) return true;
      final next = state.copyWith(
        audioId: upload.audioId,
        audioPath: upload.localPath.isEmpty ? null : upload.localPath,
        durationMs: upload.durationMs,
        // A new file arrives untrimmed.
        trim: AudioTrim.full(upload.durationMs),
        isUploading: false,
        uploadProgress: 1,
      );
      state = next.copyWith(boundaries: _fitBoundaries(next));
    } catch (_) {
      if (_uploadCancel == cancelToken) {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 0,
          durationMs: 0,
          clearAudio: true,
        );
      }
      rethrow;
    } finally {
      if (_uploadCancel == cancelToken) _uploadCancel = null;
    }
    return true;
  }

  /// Runs an AI voice-over and uses the result as the lesson audio;
  /// `true` when synthesis has started.
  Future<bool> synthesizeTts() async {
    if (SynthesizeTts.prepareText(state.text).isEmpty) return false;

    // Abort the previous upload or synthesis.
    _uploadCancel?.cancel();
    final cancelToken = _uploadCancel = CancelToken();
    state = state.copyWith(
      clearAudio: true,
      audioFileName: 'Озвучка ИИ',
      durationMs: 0,
      trim: const AudioTrim.full(0),
      clearPendingTrim: true,
      boundaries: const [],
      isUploading: true,
      isSynthesizing: true,
      uploadProgress: 0,
    );

    try {
      final upload = await ref.read(synthesizeTtsProvider)(
        text: state.text,
        cancel: cancelToken,
      );
      if (_uploadCancel != cancelToken) return true;
      final next = state.copyWith(
        audioId: upload.audioId,
        audioPath: upload.localPath.isEmpty ? null : upload.localPath,
        durationMs: upload.durationMs,
        trim: AudioTrim.full(upload.durationMs),
        isUploading: false,
        isSynthesizing: false,
        uploadProgress: 1,
      );
      state = next.copyWith(boundaries: _fitBoundaries(next));
    } catch (_) {
      if (_uploadCancel == cancelToken) {
        state = state.copyWith(
          isUploading: false,
          isSynthesizing: false,
          uploadProgress: 0,
          durationMs: 0,
          clearAudio: true,
        );
      }
      rethrow;
    } finally {
      if (_uploadCancel == cancelToken) _uploadCancel = null;
    }
    return true;
  }

  /// Aborts the upload or voice-over and clears the chosen file.
  void cancelUpload() {
    _uploadCancel?.cancel();
    _uploadCancel = null;
    state = state.copyWith(
      isUploading: false,
      isSynthesizing: false,
      uploadProgress: 0,
      durationMs: 0,
      clearAudio: true,
    );
  }

  /// Creates a lesson and refreshes the home list.
  Future<Lesson> submit() async {
    final audioId = state.audioId;
    if (audioId == null) {
      throw StateError('Файл ещё не загружен');
    }
    final accent = state.accent;
    final level = state.level;
    if (accent == null || level == null) {
      throw StateError('Акцент и уровень не выбраны');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final lesson = await ref.read(createLessonProvider)(
        CreateLessonParams(
          title: state.title,
          rawText: state.text,
          audioId: audioId,
          durationMs: state.durationMs,
          accent: accent,
          level: level,
          topicId: state.topicId,
          boundaries: state.boundaries.isEmpty ? null : state.boundaries,
          isPublic: _isPublicForRole(),
        ),
      );
      ref.invalidate(lessonsControllerProvider);
      // A new lesson lands in the library root.
      ref.invalidate(libraryControllerProvider);
      state = const AddLessonFormState();
      return lesson;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  /// Lesson visibility based on the author role; `null` lets the server pick.
  bool? _isPublicForRole() {
    final role = ref.read(authControllerProvider).user?.role;
    return switch (role) {
      UserRole.owner => state.isPublic,
      UserRole.userPro => false,
      _ => null,
    };
  }
}

final addLessonControllerProvider =
    NotifierProvider<AddLessonController, AddLessonFormState>(
      AddLessonController.new,
    );
