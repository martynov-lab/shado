import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import 'audio_dto.dart';
import 'segment_model.dart';

/// Урок в том виде, в каком его отдаёт сервер.
///
/// От [LessonModel] отличается тем, чего в кеше нет и быть не может: здесь
/// аудио — это `audio_id` и его метаданные, а в кеше — путь к скачанному файлу.
/// Смешивать их в одной модели не стоит, поэтому DTO живёт отдельно.
///
/// Сегменты переиспользуют `SegmentModel`: их JSON-форма на сервере и в кеше
/// совпадает до ключей (`index`, `text`, `start_ms`, `end_ms`).
class LessonDto {
  const LessonDto({
    required this.id,
    required this.title,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.audio,
    required this.segments,
    this.isPublic = true,
    this.deletedAt,
    this.accent,
    this.level,
    this.topic,
  });

  factory LessonDto.fromJson(Map<String, dynamic> json) => LessonDto(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    createdAt: _parseTime(json['created_at']),
    updatedAt: _parseTime(json['updated_at']),
    deletedAt: json['deleted_at'] == null
        ? null
        : _parseTime(json['deleted_at']),
    version: (json['version'] as num?)?.toInt() ?? 1,
    // Отсутствие поля держим за публичный урок: старый сервер не знал о
    // приватности.
    isPublic: json['is_public'] as bool? ?? true,
    accent: LessonAccent.parse(json['accent'] as String?),
    level: LessonLevel.parse(json['level'] as String?),
    // Тема приходит объектом `{id, name}` — второй запрос ради названия не
    // нужен.
    topic: json['topic'] is Map
        ? Topic.fromJson(Map<String, dynamic>.from(json['topic'] as Map))
        : null,
    audio: AudioDto.fromJson(json['audio'] as Map<String, dynamic>),
    segments: [
      for (final segment in (json['segments'] as List<dynamic>? ?? const []))
        SegmentModel.fromJson(segment as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final int durationMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Непустое время — урок удалён на другом устройстве и должен исчезнуть из
  /// кеша. Приходит только в дельте (`GET /v1/lessons?since=`).
  final DateTime? deletedAt;

  /// Версия агрегата. Уезжает обратно в `If-Match` при правке.
  final int version;

  /// Публичность урока (§6). Приватный виден только автору; в общем списке его
  /// не отдают, поэтому увидели ⇒ он свой.
  final bool isPublic;

  /// Категории урока (§6). `null` — сервер прислал пустое или незнакомое
  /// значение; подставлять своё на его место нельзя.
  final LessonAccent? accent;
  final LessonLevel? level;
  final Topic? topic;

  final AudioDto audio;
  final List<SegmentModel> segments;

  bool get isDeleted => deletedAt != null;

  /// Урок для домена. Путь к аудио подставляет репозиторий: он один знает, где
  /// лежит скачанный файл.
  Lesson toEntity({required String audioPath}) => Lesson(
    id: id,
    title: title,
    audioPath: audioPath,
    durationMs: durationMs,
    createdAt: createdAt,
    segments: segments.map((segment) => segment.toEntity()).toList(),
    isPublic: isPublic,
    accent: accent,
    level: level,
    topic: topic,
  );

  static DateTime _parseTime(Object? raw) =>
      DateTime.tryParse(raw as String? ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
