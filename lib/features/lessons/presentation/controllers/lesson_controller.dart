import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_providers.dart';

/// Один экземпляр плеера на экран урока: уходим с экрана — плеер уничтожается.
final lessonAudioPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, lessonId) {
      final player = AudioPlayer();
      ref.onDispose(player.dispose);
      return player;
    });

/// Позиция воспроизведения — отдельным провайдером, чтобы частые тики
/// перерисовывали только курсор на волне.
final playbackPositionProvider = StreamProvider.autoDispose
    .family<Duration, String>((ref, lessonId) {
      return ref.watch(lessonAudioPlayerProvider(lessonId)).positionStream;
    });

/// Состояние экрана урока.
class LessonState {
  const LessonState({
    required this.lesson,
    required this.speed,
    this.activeSegmentIndex,
    this.isPlaying = false,
    this.loopedSegments = const {},
  });

  final Lesson lesson;
  final double speed;

  /// Индекс куска, который сейчас заряжен в плеер (играет или на паузе).
  final int? activeSegmentIndex;
  final bool isPlaying;

  /// Индексы кусков с включённым зацикливанием.
  final Set<int> loopedSegments;

  bool get isSlow => speed == kSlowSpeed;

  bool isSegmentPlaying(int index) => activeSegmentIndex == index && isPlaying;

  bool isSegmentLooped(int index) => loopedSegments.contains(index);

  LessonState copyWith({
    Lesson? lesson,
    double? speed,
    int? activeSegmentIndex,
    bool clearActiveSegment = false,
    bool? isPlaying,
    Set<int>? loopedSegments,
  }) {
    return LessonState(
      lesson: lesson ?? this.lesson,
      speed: speed ?? this.speed,
      activeSegmentIndex: clearActiveSegment
          ? null
          : (activeSegmentIndex ?? this.activeSegmentIndex),
      isPlaying: isPlaying ?? this.isPlaying,
      loopedSegments: loopedSegments ?? this.loopedSegments,
    );
  }
}

/// Проигрывание кусков, зацикливание, скорость и правка границ.
class LessonController extends AsyncNotifier<LessonState> {
  LessonController(this.lessonId);

  final String lessonId;

  /// Скорость и флаги loop живут в контроллере: они переживают пересборку
  /// [build], в отличие от состояния.
  double _speed = kNormalSpeed;
  final Set<int> _loopedSegments = <int>{};

  AudioPlayer get _player => ref.read(lessonAudioPlayerProvider(lessonId));

  @override
  Future<LessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    // Именно watch: плеер под autoDispose и должен жить, пока жив контроллер.
    final player = ref.watch(lessonAudioPlayerProvider(lessonId));
    final subscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(subscription.cancel);
    return LessonState(
      lesson: lesson,
      speed: _speed,
      loopedSegments: Set.unmodifiable(_loopedSegments),
    );
  }

  void _onPlayerState(PlayerState playerState) {
    final current = state.value;
    if (current == null) return;
    final isPlaying =
        playerState.playing &&
        playerState.processingState != ProcessingState.completed;
    if (isPlaying != current.isPlaying) {
      state = AsyncValue.data(current.copyWith(isPlaying: isPlaying));
    }
  }

  /// Тумблер play/pause для куска. Запуск другого куска останавливает текущий.
  Future<void> togglePlay(int index) async {
    final current = state.value;
    if (current == null) return;
    if (current.activeSegmentIndex != index) {
      await _startSegment(current, index);
      return;
    }
    final player = _player;
    if (player.playing) {
      await player.pause();
      return;
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }

  Future<void> _startSegment(LessonState current, int index) async {
    final segment = current.lesson.segments[index];
    final player = _player;
    await player.stop();
    await player.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.file(current.lesson.audioPath),
        start: Duration(milliseconds: segment.startMs),
        end: Duration(milliseconds: segment.endMs),
      ),
    );
    await player.setLoopMode(
      _loopedSegments.contains(index) ? LoopMode.one : LoopMode.off,
    );
    await player.setSpeed(_speed);
    state = AsyncValue.data(
      current.copyWith(activeSegmentIndex: index, isPlaying: true),
    );
    // play() завершается только по окончании воспроизведения — не ждём его.
    unawaited(player.play());
  }

  Future<void> toggleLoop(int index) async {
    final current = state.value;
    if (current == null) return;
    final enabled = !_loopedSegments.contains(index);
    if (enabled) {
      _loopedSegments.add(index);
    } else {
      _loopedSegments.remove(index);
    }
    if (current.activeSegmentIndex == index) {
      await _player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);
    }
    state = AsyncValue.data(
      current.copyWith(loopedSegments: Set.unmodifiable(_loopedSegments)),
    );
  }

  /// Скорость на весь урок: применяется на лету и к последующим запускам.
  Future<void> setSpeed(double speed) async {
    final current = state.value;
    if (current == null || current.speed == speed) return;
    _speed = speed;
    state = AsyncValue.data(current.copyWith(speed: speed));
    await _player.setSpeed(speed);
  }

  /// Сохраняет новые границы после перетаскивания метки на волне.
  Future<void> updateBoundaries(List<int> boundaries) async {
    final current = state.value;
    if (current == null) return;
    final updated = await ref.read(updateSegmentBoundariesProvider)(
      lessonId: lessonId,
      boundaries: boundaries,
    );
    // Заряженный в плеер кусок мог поменять границы — сбрасываем источник.
    await _player.stop();
    state = AsyncValue.data(
      current.copyWith(
        lesson: updated,
        clearActiveSegment: true,
        isPlaying: false,
      ),
    );
  }
}

final lessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LessonController, LessonState, String>(LessonController.new);
