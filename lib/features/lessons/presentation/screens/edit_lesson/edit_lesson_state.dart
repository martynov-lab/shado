import '../../../domain/entities/audio_trim.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/usecases/create_lesson.dart';

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
