import '../../../../core/error/failures.dart';
import 'segment.dart';

/// Урок: аудиофайл, разбитый на куски текста с ручной разметкой границ.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.durationMs,
    required this.createdAt,
    required this.segments,
  });

  /// Создаёт урок с равномерно расставленными начальными границами:
  /// сегмент `i` получает `[durationMs * i / N, durationMs * (i + 1) / N]`.
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
      throw const ValidationFailure('Длительность аудио должна быть больше нуля');
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
      // Путь может быть как локальным файлом, так и удалённым URL в будущем.
      audioPath: audioPath,
      durationMs: durationMs,
      createdAt: createdAt.toUtc(),
      segments: segments,
    );
  }

  final String id;
  final String title;

  /// Путь к аудио: сейчас всегда локальный файл, позже может быть URL.
  final String audioPath;
  final int durationMs;

  /// Время создания в UTC.
  final DateTime createdAt;
  final List<Segment> segments;

  int get segmentCount => segments.length;

  /// Границы кусков: `N + 1` значение, где `b[0] = 0`, `b[N] = durationMs`.
  List<int> get boundaries {
    if (segments.isEmpty) return const [];
    return [
      for (final segment in segments) segment.startMs,
      segments.last.endMs,
    ];
  }

  /// Пересобирает сегменты по новому набору границ, сохраняя тексты.
  Lesson withBoundaries(List<int> boundaries) {
    if (boundaries.length != segments.length + 1) {
      throw ValidationFailure(
        'Ожидалось ${segments.length + 1} границ, получено ${boundaries.length}',
      );
    }
    for (var i = 1; i < boundaries.length; i++) {
      if (boundaries[i] <= boundaries[i - 1]) {
        throw const ValidationFailure('Границы должны идти строго по возрастанию');
      }
    }
    return copyWith(
      segments: [
        for (var i = 0; i < segments.length; i++)
          segments[i].copyWith(startMs: boundaries[i], endMs: boundaries[i + 1]),
      ],
    );
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? audioPath,
    int? durationMs,
    DateTime? createdAt,
    List<Segment>? segments,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      segments: segments ?? this.segments,
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
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    audioPath,
    durationMs,
    createdAt,
    Object.hashAll(segments),
  );

  @override
  String toString() => 'Lesson($id, "$title", ${segments.length} сегментов)';
}
