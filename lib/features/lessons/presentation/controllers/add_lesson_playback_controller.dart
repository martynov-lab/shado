import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'add_lesson_controller.dart';

/// Плеер экрана создания урока.
///
/// Играет только что загруженный файл целиком: метки ставятся на слух, а не
/// на глаз по волне, — так слышно, попадает ли граница в паузу между фразами.
///
/// `autoDispose`, в отличие от самой формы: та переживает уход с экрана вместе
/// с набранным текстом, а звук должен смолкнуть вместе с закрытием экрана.
final addLessonPlayerProvider = Provider.autoDispose<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Позиция воспроизведения — отдельным провайдером, чтобы частые тики
/// перерисовывали только ползунок на волне.
final addPlaybackPositionProvider = StreamProvider.autoDispose<Duration>(
  (ref) => ref.watch(addLessonPlayerProvider).positionStream,
);

/// Где стоит ползунок и играет ли аудио прямо сейчас.
class AddLessonPlayback {
  const AddLessonPlayback({this.playheadMs = 0, this.isPlaying = false});

  /// Откуда играть: ползунок на волне, который перетаскивают вручную и на
  /// котором аудио останавливается по паузе. В миллисекундах файла.
  final int playheadMs;

  final bool isPlaying;

  AddLessonPlayback copyWith({int? playheadMs, bool? isPlaying}) =>
      AddLessonPlayback(
        playheadMs: playheadMs ?? this.playheadMs,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}

/// Прослушивание файла на экране создания урока.
///
/// Живёт отдельно от [AddLessonController], потому что читает форму, но не
/// пишет в неё: разметка и текст плеера не касаются, а плеер — их.
class AddLessonPlaybackController extends Notifier<AddLessonPlayback> {
  /// Путь, который уже заряжен в плеер: второй раз тот же файл не открываем.
  String? _loadedPath;

  AudioPlayer get _player => ref.read(addLessonPlayerProvider);

  AddLessonFormState get _form => ref.read(addLessonControllerProvider);

  @override
  AddLessonPlayback build() {
    // Именно watch: плеер под autoDispose и должен жить, пока жив контроллер.
    final player = ref.watch(addLessonPlayerProvider);
    final stateSubscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(stateSubscription.cancel);
    final positionSubscription = player.positionStream.listen(_onPosition);
    ref.onDispose(positionSubscription.cancel);

    // Выбрали другой файл — ползунок и заряженный источник от прежнего уже не
    // годятся. Следим только за `audio_id`: на каждую букву текста
    // перезаряжать плеер не за чем.
    ref.listen(addLessonControllerProvider.select((form) => form.audioId), (
      _,
      _,
    ) {
      _loadedPath = null;
      state = const AddLessonPlayback();
      unawaited(_stopQuietly());
    });

    return const AddLessonPlayback();
  }

  /// Снимает звук с прежнего файла.
  ///
  /// Форма обнуляется и при удачном создании урока, а вместе с уходом с экрана
  /// закрывается и плеер — к этому моменту останавливать уже нечего, и ошибку
  /// такой гонки нести наверх незачем.
  Future<void> _stopQuietly() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Файл заряжен целиком, поэтому конец обрезанной дорожки стережём сами:
  /// дальше него аудио к уроку уже не относится.
  void _onPosition(Duration position) {
    if (!state.isPlaying) return;
    final form = _form;
    if (form.isTrimming) return;
    if (position.inMilliseconds < form.trim.endMs) return;
    unawaited(_player.pause());
    unawaited(seek(form.trim.endMs));
  }

  void _onPlayerState(PlayerState playerState) {
    final finished = playerState.processingState == ProcessingState.completed;
    if (finished && playerState.playing) {
      // Доиграв до конца, плеер остаётся «играющим». Снимаем это сами: иначе
      // перетаскивание ползунка внезапно запустит звук, ведь seek у играющего
      // плеера продолжает воспроизведение.
      unawaited(_player.pause());
    }
    final isPlaying = playerState.playing && !finished;
    if (isPlaying == state.isPlaying) return;
    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Ставит ползунок в заданное место аудио. Если оно играет, продолжает с
  /// новой точки, не прерываясь.
  ///
  /// Во время обрезки ползунок ходит по файлу целиком — иначе не послушать то,
  /// что собираются отрезать.
  Future<void> seek(int positionMs) async {
    final form = _form;
    if (form.durationMs <= 0) return;
    final clamped = form.isTrimming
        ? positionMs.clamp(0, form.durationMs)
        : form.trim.clampMs(positionMs);
    state = state.copyWith(playheadMs: clamped);
    if (_player.audioSource != null) {
      await _player.seek(Duration(milliseconds: clamped));
    }
  }

  /// Тумблер play/pause: играет с ползунка, а по паузе оставляет ползунок
  /// там, где аудио остановилось.
  Future<void> togglePlay() async {
    final form = _form;
    final path = form.audioPath;
    // Файла ещё нет или он не догрузился — играть нечего.
    if (path == null || form.durationMs <= 0) return;

    final player = _player;
    // Сверяемся со своим состоянием, а не с `player.playing`: у доигравшего до
    // конца плеера тот остаётся поднятым.
    if (state.isPlaying) {
      await player.pause();
      await seek(player.position.inMilliseconds);
      return;
    }
    if (_loadedPath != path) {
      await player.setFilePath(path);
      _loadedPath = path;
    }
    // С самого конца играть нечего — начинаем дорожку заново.
    await seek(
      !form.isTrimming && state.playheadMs >= form.trim.endMs
          ? form.trim.startMs
          : state.playheadMs,
    );
    // play() завершается только по окончании воспроизведения — не ждём его.
    unawaited(player.play());
  }
}

final addLessonPlaybackProvider =
    NotifierProvider.autoDispose<
      AddLessonPlaybackController,
      AddLessonPlayback
    >(AddLessonPlaybackController.new);
