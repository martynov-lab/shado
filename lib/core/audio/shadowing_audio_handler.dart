import 'package:audio_service/audio_service.dart';

import 'lesson_remote_control.dart';

/// Мост между системной медиа-сессией и активным экраном урока.
///
/// Живёт всё время работы приложения (audio_service требует единственный
/// handler-синглтон), но своей логики не содержит: команды системы — кнопки
/// гарнитуры, экран блокировки, уведомление — он перенаправляет в
/// [LessonRemoteControl] открытого урока, а обратно публикует, звучит ли плеер и
/// что именно.
///
/// Двойной и тройной клик гарнитуры отдельно считать не нужно: пока в сессии
/// объявлены `skipToNext`/`skipToPrevious`, платформа сама трактует двойной клик
/// как «вперёд», тройной — как «назад» и зовёт [skipToNext]/[skipToPrevious].
class ShadowingAudioHandler extends BaseAudioHandler {
  /// Урок, который сейчас держит сессию. `null` — вне экрана урока.
  LessonRemoteControl? _control;

  /// Открытый урок берёт управление сессией на себя.
  void attach(LessonRemoteControl control) => _control = control;

  /// Урок ушёл с экрана. Снимаем управление только за собой: autoDispose нового
  /// плеера может опередить dispose старого, и тот не должен погасить чужую
  /// сессию.
  void detach(LessonRemoteControl control) {
    if (!identical(_control, control)) return;
    _control = null;
    _publishStopped();
  }

  /// Публикует, что звучит: текст сегмента и флаг `playing`. Флаг важен вдвойне —
  /// по нему система решает, что прислать одиночным кликом (play или pause).
  void setNowPlaying({
    required String id,
    required String title,
    required String album,
    required Duration duration,
    required bool playing,
  }) {
    mediaItem.add(
      MediaItem(id: id, title: title, album: album, duration: duration),
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        processingState: AudioProcessingState.ready,
        playing: playing,
      ),
    );
  }

  void _publishStopped() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  // Система вызывает эти методы по кнопкам сессии. Одиночный клик приходит как
  // play или pause в зависимости от опубликованного `playing` — оба сводим к
  // одному тумблеру, как большая кнопка плеера.
  @override
  Future<void> play() async => _control?.remoteToggle();

  @override
  Future<void> pause() async => _control?.remoteToggle();

  @override
  Future<void> skipToNext() async => _control?.remoteNext();

  @override
  Future<void> skipToPrevious() async => _control?.remotePrevious();

  @override
  Future<void> stop() async {
    _control?.remoteStop();
    await super.stop();
  }
}
