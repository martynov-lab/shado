/// Аудио, принятое сервером: с этого начинается создание урока.
///
/// Длительность считает сервер, локальный замер через плеер на этом пути
/// больше не нужен.
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

  /// Файл в кеше приложения — тот же, что только что отправили. Экран создания
  /// играет его с любого места, чтобы метки можно было ставить на слух ещё до
  /// сохранения урока. Пусто — копию в кеш положить не удалось.
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
