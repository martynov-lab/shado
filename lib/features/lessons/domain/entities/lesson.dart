import '../../../../core/error/failures.dart';
import 'audio_trim.dart';
import 'lesson_category.dart';
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
    this.audioId = '',
    this.accent,
    this.level,
    this.topic,
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

  /// Путь к готовому к воспроизведению локальному файлу. Репозиторий следит,
  /// чтобы файл был на месте, докачивая его при необходимости.
  final String audioPath;

  /// Аудио на сервере. По нему берутся пики волны; у урока, собранного в
  /// тестах или ещё не побывавшего на сервере, пусто.
  final String audioId;

  /// Длительность файла целиком — обрезка её не меняет.
  final int durationMs;

  /// Акцент диктора и уровень английского. Заполняются на экране создания и
  /// приходят с сервера; `null` — у урока, собранного в тестах или пришедшего
  /// без этих полей.
  final LessonAccent? accent;
  final LessonLevel? level;

  /// Тема из справочника сервера. `null` — сервер её ещё не подставил.
  final Topic? topic;

  /// Время создания в UTC.
  final DateTime createdAt;
  final List<Segment> segments;

  int get segmentCount => segments.length;

  /// Отрезок файла, попавший в урок. Куски идут встык и покрывают его целиком,
  /// поэтому обрезка — это и есть края крайних кусков.
  AudioTrim get trim => segments.isEmpty
      ? AudioTrim.full(durationMs)
      : AudioTrim(
          startMs: segments.first.startMs,
          endMs: segments.last.endMs,
        );

  /// Границы кусков: `N + 1` значение, где `b[0]` и `b[N]` — края [trim].
  List<int> get boundaries {
    if (segments.isEmpty) return const [];
    return [
      for (final segment in segments) segment.startMs,
      segments.last.endMs,
    ];
  }

  /// Пересобирает сегменты по новому набору границ, сохраняя тексты.
  Lesson withBoundaries(List<int> boundaries) {
    return withSegments(
      texts: [for (final segment in segments) segment.text],
      boundaries: boundaries,
    );
  }

  /// Пересобирает урок под новую разбивку: тексты кусков и их границы задаются
  /// вместе, поэтому число кусков может измениться.
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
        throw const ValidationFailure('Границы должны идти строго по возрастанию');
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
    accent,
    level,
    topic,
  );

  @override
  String toString() => 'Lesson($id, "$title", ${segments.length} сегментов)';
}
