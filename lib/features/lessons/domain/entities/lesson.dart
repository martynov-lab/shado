import '../../../../core/error/failures.dart';
import 'audio_trim.dart';
import 'lesson_category.dart';
import 'segment.dart';

/// Lesson: an audio file split into text segments with manual boundaries.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.durationMs,
    required this.createdAt,
    required this.segments,
    this.audioId = '',
    this.isPublic = true,
    this.accent,
    this.level,
    this.topic,
  });

  /// Creates a lesson with evenly spaced segment boundaries.
  factory Lesson.withEvenBoundaries({
    required String id,
    required String title,
    required String audioPath,
    required int durationMs,
    required DateTime createdAt,
    required List<String> segmentTexts,
  }) {
    if (segmentTexts.isEmpty) {
      throw const ValidationFailure('Урок должен содержать хотя бы один кусок');
    }
    if (durationMs <= 0) {
      throw const ValidationFailure(
        'Длительность аудио должна быть больше нуля',
      );
    }
    final count = segmentTexts.length;
    final segments = <Segment>[
      for (var i = 0; i < count; i++)
        Segment(
          index: i,
          text: segmentTexts[i],
          startMs: durationMs * i ~/ count,
          endMs: durationMs * (i + 1) ~/ count,
        ),
    ];
    return Lesson(
      id: id,
      title: title,
      audioPath: audioPath,
      durationMs: durationMs,
      createdAt: createdAt.toUtc(),
      segments: segments,
    );
  }

  final String id;
  final String title;

  /// Path to a local file ready for playback.
  final String audioPath;

  /// Server-side audio the waveform peaks are taken from.
  final String audioId;

  /// Duration of the whole file; trimming does not change it.
  final int durationMs;

  /// Lesson visibility; a private one is visible to its author only.
  final bool isPublic;

  bool get isPrivate => !isPublic;

  /// Speaker accent and English level; `null` when unset.
  final LessonAccent? accent;
  final LessonLevel? level;

  /// Topic from the server directory.
  final Topic? topic;

  /// Creation time in UTC.
  final DateTime createdAt;
  final List<Segment> segments;

  int get segmentCount => segments.length;

  /// File range that made it into the lesson — the outer segment edges.
  AudioTrim get trim => segments.isEmpty
      ? AudioTrim.full(durationMs)
      : AudioTrim(startMs: segments.first.startMs, endMs: segments.last.endMs);

  /// Segment boundaries: `N + 1` values whose ends match [trim].
  List<int> get boundaries {
    if (segments.isEmpty) return const [];
    return [
      for (final segment in segments) segment.startMs,
      segments.last.endMs,
    ];
  }

  /// Rebuilds segments for a new set of boundaries, keeping the texts.
  Lesson withBoundaries(List<int> boundaries) {
    return withSegments(
      texts: [for (final segment in segments) segment.text],
      boundaries: boundaries,
    );
  }

  /// Rebuilds the lesson for a new split — segment texts with boundaries.
  Lesson withSegments({
    required List<String> texts,
    required List<int> boundaries,
  }) {
    if (texts.isEmpty) {
      throw const ValidationFailure('Урок должен содержать хотя бы один кусок');
    }
    if (boundaries.length != texts.length + 1) {
      throw ValidationFailure(
        'Ожидалось ${texts.length + 1} границ, получено ${boundaries.length}',
      );
    }
    for (var i = 1; i < boundaries.length; i++) {
      if (boundaries[i] <= boundaries[i - 1]) {
        throw const ValidationFailure(
          'Границы должны идти строго по возрастанию',
        );
      }
    }
    return copyWith(
      segments: [
        for (var i = 0; i < texts.length; i++)
          Segment(
            index: i,
            text: texts[i],
            startMs: boundaries[i],
            endMs: boundaries[i + 1],
          ),
      ],
    );
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? audioPath,
    String? audioId,
    int? durationMs,
    DateTime? createdAt,
    List<Segment>? segments,
    bool? isPublic,
    LessonAccent? accent,
    LessonLevel? level,
    Topic? topic,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      audioId: audioId ?? this.audioId,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      segments: segments ?? this.segments,
      isPublic: isPublic ?? this.isPublic,
      accent: accent ?? this.accent,
      level: level ?? this.level,
      topic: topic ?? this.topic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Lesson) return false;
    if (other.segments.length != segments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (other.segments[i] != segments[i]) return false;
    }
    return other.id == id &&
        other.title == title &&
        other.audioPath == audioPath &&
        other.durationMs == durationMs &&
        other.createdAt == createdAt &&
        other.isPublic == isPublic &&
        other.accent == accent &&
        other.level == level &&
        other.topic == topic;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    audioPath,
    durationMs,
    createdAt,
    Object.hashAll(segments),
    isPublic,
    accent,
    level,
    topic,
  );

  @override
  String toString() => 'Lesson($id, "$title", ${segments.length} сегментов)';
}
