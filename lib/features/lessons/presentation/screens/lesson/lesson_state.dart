import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/segment.dart';
import '../../../domain/entities/segment_range.dart';

/// State of the lesson screen.
class LessonState {
  const LessonState({
    required this.lesson,
    required this.speed,
    this.activeRange,
    this.isPlaying = false,
    this.isLooped = false,
    this.isSelecting = false,
    this.selection,
    this.committedRange,
    this.focusedIndex,
    this.countdown,
  });

  final Lesson lesson;
  final double speed;

  /// What is loaded into the player: one segment or a range.
  final SegmentRange? activeRange;

  final bool isPlaying;

  /// Whether repeat is on for the loaded range.
  final bool isLooped;

  /// Whether segment selection mode is on.
  final bool isSelecting;

  /// Selected adjacent segments.
  final SegmentRange? selection;

  /// Pinned multi-segment range; `null` means the player shows a single
  /// segment [currentIndex].
  final SegmentRange? committedRange;

  /// Keyboard-focused segment; `null` when the keyboard was never used.
  final int? focusedIndex;

  /// Current countdown number; `null` when no countdown runs.
  final int? countdown;

  bool get isSlow => speed == kSlowSpeed;

  /// Segment for the player panel: the focused one or the first.
  int get currentIndex {
    final count = lesson.segmentCount;
    if (count == 0) return 0;
    return (focusedIndex ?? 0).clamp(0, count - 1);
  }

  Segment get currentSegment => lesson.segments[currentIndex];

  /// What the player shows: the pinned range or the current segment.
  SegmentRange get playerRange =>
      committedRange ?? SegmentRange.single(currentIndex);

  /// Texts of the shown range segments joined by spaces.
  String get playerText {
    final range = playerRange;
    final segments = lesson.segments;
    return [
      for (var i = range.start; i <= range.end && i < segments.length; i++)
        segments[i].text,
    ].join(' ');
  }

  int get playerStartMs => lesson.segments[playerRange.start].startMs;

  int get playerEndMs => lesson.segments[playerRange.end].endMs;

  /// Whether the player plays exactly what it shows.
  bool get isPlayerPlaying => isPlaying && activeRange == playerRange;

  bool get canGoPrevious => playerRange.start > 0;

  bool get canGoNext => playerRange.end < lesson.segmentCount - 1;

  bool isSegmentActive(int index) => activeRange?.contains(index) ?? false;

  bool isSegmentPlaying(int index) => isPlaying && isSegmentActive(index);

  bool isSegmentSelected(int index) => selection?.contains(index) ?? false;

  /// Whether the selected range itself is playing.
  bool get isSelectionPlaying =>
      isPlaying && selection != null && activeRange == selection;

  /// How long the whole selection sounds.
  int get selectionDurationMs {
    final range = selection;
    if (range == null) return 0;
    final segments = lesson.segments;
    if (range.end >= segments.length) return 0;
    return segments[range.end].endMs - segments[range.start].startMs;
  }

  LessonState copyWith({
    Lesson? lesson,
    double? speed,
    SegmentRange? activeRange,
    bool clearActiveRange = false,
    bool? isPlaying,
    bool? isLooped,
    bool? isSelecting,
    SegmentRange? selection,
    bool clearSelection = false,
    SegmentRange? committedRange,
    bool clearCommittedRange = false,
    int? focusedIndex,
    int? countdown,
    bool clearCountdown = false,
  }) {
    return LessonState(
      lesson: lesson ?? this.lesson,
      speed: speed ?? this.speed,
      activeRange: clearActiveRange ? null : (activeRange ?? this.activeRange),
      isPlaying: isPlaying ?? this.isPlaying,
      isLooped: isLooped ?? this.isLooped,
      isSelecting: isSelecting ?? this.isSelecting,
      selection: clearSelection ? null : (selection ?? this.selection),
      committedRange: clearCommittedRange
          ? null
          : (committedRange ?? this.committedRange),
      focusedIndex: focusedIndex ?? this.focusedIndex,
      countdown: clearCountdown ? null : (countdown ?? this.countdown),
    );
  }
}
