import 'waveform_peaks.dart';

/// Server-side audio; the content behind an [id] never changes.
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

  /// Checksum used to verify a downloaded file.
  final String sha256;

  /// File duration as reported by the server.
  final int durationMs;

  /// Waveform peaks when the server sent them.
  final WaveformPeaks? peaks;

  /// Extension for the cached file name.
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
