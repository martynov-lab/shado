import '../../../domain/entities/audio_trim.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/usecases/create_lesson.dart';

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
  final String? accent;
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

  /// Whether the lesson can be created; [needsAccent] is set for languages
  /// that have accents — without one the server answers `422`.
  bool isReady({required bool needsAccent}) =>
      !isSubmitting &&
      !isUploading &&
      // An unfinished trim must be applied or cancelled first.
      !isTrimming &&
      title.trim().isNotEmpty &&
      segmentCount > 0 &&
      audioId != null &&
      (!needsAccent || accent != null) &&
      level != null;

  AddLessonFormState copyWith({
    String? title,
    String? text,
    String? accent,
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
