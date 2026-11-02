import '../../domain/entities/phrase.dart';
import 'audio_dto.dart';

/// A phrase as the server sends it and as the cache keeps it.
class PhraseModel {
  const PhraseModel({
    required this.id,
    required this.text,
    required this.audio,
    required this.durationMs,
    this.translations = const {},
    this.audioPath = '',
    this.startMs,
    this.endMs,
    this.sourceLessonId,
  });

  /// The server shape: the audio arrives as an object.
  factory PhraseModel.fromJson(Map<String, dynamic> json) => PhraseModel(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
    translations: _translationsOf(json['translations']),
    audio: AudioDto.fromJson(Map<String, dynamic>.from(json['audio'] as Map)),
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    startMs: (json['start_ms'] as num?)?.toInt(),
    endMs: (json['end_ms'] as num?)?.toInt(),
    sourceLessonId: json['source_lesson_id'] as String?,
  );

  /// The cache shape written by [toCacheJson].
  factory PhraseModel.fromCacheJson(Map<String, dynamic> json) => PhraseModel(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
    translations: _translationsOf(json['translations']),
    audio: AudioDto(
      id: json['audio_id'] as String? ?? '',
      contentType: json['audio_content_type'] as String? ?? '',
      sizeBytes: (json['audio_size_bytes'] as num?)?.toInt() ?? 0,
      sha256: json['audio_sha256'] as String? ?? '',
      durationMs: (json['audio_duration_ms'] as num?)?.toInt() ?? 0,
    ),
    audioPath: json['audio_path'] as String? ?? '',
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    startMs: (json['start_ms'] as num?)?.toInt(),
    endMs: (json['end_ms'] as num?)?.toInt(),
    sourceLessonId: json['source_lesson_id'] as String?,
  );

  final String id;
  final String text;
  final Map<String, String> translations;

  /// The whole file; for a phrase from a story it is the story audio.
  final AudioDto audio;

  /// Local copy of [audio]; empty until it is downloaded.
  final String audioPath;

  final int durationMs;
  final int? startMs;
  final int? endMs;
  final String? sourceLessonId;

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'text': text,
    'translations': translations,
    'audio_id': audio.id,
    'audio_content_type': audio.contentType,
    'audio_size_bytes': audio.sizeBytes,
    'audio_sha256': audio.sha256,
    'audio_duration_ms': audio.durationMs,
    'audio_path': audioPath,
    'duration_ms': durationMs,
    'start_ms': ?startMs,
    'end_ms': ?endMs,
    'source_lesson_id': ?sourceLessonId,
  };

  PhraseModel withAudioPath(String audioPath) => PhraseModel(
    id: id,
    text: text,
    translations: translations,
    audio: audio,
    audioPath: audioPath,
    durationMs: durationMs,
    startMs: startMs,
    endMs: endMs,
    sourceLessonId: sourceLessonId,
  );

  Phrase toEntity() => Phrase(
    id: id,
    text: text,
    translations: translations,
    audioId: audio.id,
    audioPath: audioPath,
    durationMs: durationMs,
    startMs: startMs,
    endMs: endMs,
    sourceLessonId: sourceLessonId,
  );

  /// The request shape of a phrase inside `PUT /v1/lessons/{id}`.
  static Map<String, dynamic> requestJson(Phrase phrase) => {
    'id': phrase.id,
    'text': phrase.text,
    'translations': {
      for (final MapEntry(:key, :value) in phrase.translations.entries)
        if (value.trim().isNotEmpty) key: value.trim(),
    },
    'audio_id': phrase.audioId,
    'start_ms': ?phrase.startMs,
    'end_ms': ?phrase.endMs,
    'source_lesson_id': ?phrase.sourceLessonId,
  };

  static Map<String, String> _translationsOf(Object? raw) => {
    if (raw is Map)
      for (final MapEntry(:key, :value) in raw.entries)
        if (value is String) '$key': value,
  };
}
