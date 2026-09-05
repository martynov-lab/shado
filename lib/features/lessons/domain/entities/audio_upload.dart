/// Audio accepted by the server; lesson creation starts from it.
class AudioUpload {
  const AudioUpload({
    required this.audioId,
    required this.durationMs,
    required this.sizeBytes,
    this.localPath = '',
  });

  final String audioId;
  final int durationMs;
  final int sizeBytes;

  /// Copy of the file in the app cache; empty when it could not be stored.
  final String localPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioUpload &&
          other.audioId == audioId &&
          other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(audioId, durationMs);

  @override
  String toString() => 'AudioUpload($audioId, $durationMs ms)';
}
