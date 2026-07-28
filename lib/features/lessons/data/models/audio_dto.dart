import 'waveform_peaks.dart';

/// Аудио на сервере. Приходит из `POST /v1/audio` и внутри урока (`lesson.audio`).
///
/// Файл иммутабелен: содержимое под одним [id] не меняется никогда, поэтому
/// локальный кеш по нему не нуждается в инвалидации.
class AudioDto {
  const AudioDto({
    required this.id,
    required this.contentType,
    required this.sizeBytes,
    required this.sha256,
    required this.durationMs,
    this.url,
    this.peaks,
  });

  factory AudioDto.fromJson(Map<String, dynamic> json) => AudioDto(
    id: json['id'] as String,
    url: json['url'] as String?,
    contentType: json['content_type'] as String? ?? 'application/octet-stream',
    sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    sha256: json['sha256'] as String? ?? '',
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    peaks: json['peaks'] == null
        ? null
        : WaveformPeaks.fromJson(json['peaks'] as Map<String, dynamic>),
  );

  final String id;
  final String? url;
  final String contentType;
  final int sizeBytes;

  /// Контрольная сумма: по ней проверяется целостность скачанного файла.
  final String sha256;

  /// Длительность считает сервер — локальный замер на этом пути не нужен.
  final int durationMs;

  /// Пики приходят сразу после загрузки: волну можно рисовать, не спрашивая
  /// `/peaks` отдельно.
  final WaveformPeaks? peaks;

  /// Расширение для имени файла в кеше.
  String get fileExtension => extensionForContentType(contentType);

  static String extensionForContentType(String contentType) {
    final type = contentType.split(';').first.trim().toLowerCase();
    return switch (type) {
      'audio/mpeg' || 'audio/mp3' => 'mp3',
      'audio/mp4' || 'audio/m4a' || 'audio/x-m4a' => 'm4a',
      'audio/aac' => 'aac',
      'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
      'audio/flac' || 'audio/x-flac' => 'flac',
      'audio/ogg' || 'application/ogg' => 'ogg',
      _ => 'bin',
    };
  }
}
