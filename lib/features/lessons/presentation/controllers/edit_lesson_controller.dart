import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import 'lesson_providers.dart';
import 'lessons_controller.dart';

/// Плеер экрана правки: играет файл целиком, а не вырезанный кусок, — так
/// слышно, попадает ли метка в паузу между фразами.
final editLessonPlayerProvider = Provider.autoDispose
    .family<AudioPlayer, String>((ref, lessonId) {
      final player = AudioPlayer();
      ref.onDispose(player.dispose);
      return player;
    });

/// Позиция воспроизведения — отдельным провайдером, чтобы частые тики
/// перерисовывали только ползунок на волне.
final editPlaybackPositionProvider = StreamProvider.autoDispose
    .family<Duration, String>((ref, lessonId) {
      return ref.watch(editLessonPlayerProvider(lessonId)).positionStream;
    });

/// Состояние экрана правки урока: та же разметка, что и при создании, но
/// поверх уже импортированного аудио.
class EditLessonState {
  const EditLessonState({
    required this.lesson,
    required this.title,
    required this.text,
    required this.boundaries,
    this.playheadMs = 0,
    this.isPlaying = false,
    this.isSaving = false,
  });

  final Lesson lesson;
  final String title;
  final String text;
  final List<int> boundaries;

  /// Откуда играть: ползунок на волне, который перетаскивают вручную и на
  /// котором аудио останавливается по паузе.
  final int playheadMs;

  final bool isPlaying;
  final bool isSaving;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  bool get canSave => !isSaving && title.trim().isNotEmpty && segmentCount > 0;

  EditLessonState copyWith({
    String? title,
    String? text,
    List<int>? boundaries,
    int? playheadMs,
    bool? isPlaying,
    bool? isSaving,
  }) {
    return EditLessonState(
      lesson: lesson,
      title: title ?? this.title,
      text: text ?? this.text,
      boundaries: boundaries ?? this.boundaries,
      playheadMs: playheadMs ?? this.playheadMs,
      isPlaying: isPlaying ?? this.isPlaying,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Правка урока: разбивка текста, границы кусков на волне и прослушивание
/// аудио с любого места.
class EditLessonController extends AsyncNotifier<EditLessonState> {
  EditLessonController(this.lessonId);

  final String lessonId;

  AudioPlayer get _player => ref.read(editLessonPlayerProvider(lessonId));

  @override
  Future<EditLessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    // Именно watch: плеер под autoDispose и должен жить, пока жив контроллер.
    final player = ref.watch(editLessonPlayerProvider(lessonId));
    final subscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(subscription.cancel);
    return EditLessonState(
      lesson: lesson,
      title: lesson.title,
      text: initialText(lesson),
      boundaries: lesson.boundaries,
    );
  }

  void _onPlayerState(PlayerState playerState) {
    final current = state.value;
    if (current == null) return;
    final finished = playerState.processingState == ProcessingState.completed;
    if (finished && playerState.playing) {
      // Доиграв до конца, плеер остаётся «играющим». Снимаем это сами: иначе
      // перетаскивание ползунка внезапно запустит звук, ведь seek у играющего
      // плеера продолжает воспроизведение.
      unawaited(_player.pause());
    }
    // Ползунок остаётся там, откуда включали, — кусок легко переслушать той же
    // кнопкой.
    final isPlaying = playerState.playing && !finished;
    if (isPlaying == current.isPlaying) return;
    state = AsyncValue.data(current.copyWith(isPlaying: isPlaying));
  }

  /// Текст урока обратно одной строкой — в том виде, в каком его вводили.
  static String initialText(Lesson lesson) => lesson.segments
      .map((segment) => segment.text)
      .join(' $kSegmentDelimiter ');

  void setTitle(String title) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(title: title));
  }

  /// Число кусков задаёт текст, поэтому метки подстраиваются под него.
  void setText(String text) {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(text: text);
    state = AsyncValue.data(
      next.copyWith(
        boundaries: next.segmentCount == 0
            ? next.boundaries
            : SegmentBoundaries.resize(
                next.boundaries,
                next.segmentCount,
                next.lesson.durationMs,
              ),
      ),
    );
  }

  void setBoundaries(List<int> boundaries) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(boundaries: boundaries));
  }

  /// Ставит ползунок в заданное место аудио. Если оно играет, продолжает с
  /// новой точки, не прерываясь.
  Future<void> seek(int positionMs) async {
    final current = state.value;
    if (current == null) return;
    final clamped = positionMs.clamp(0, current.lesson.durationMs);
    state = AsyncValue.data(current.copyWith(playheadMs: clamped));
    if (_player.audioSource != null) {
      await _player.seek(Duration(milliseconds: clamped));
    }
  }

  /// Тумблер play/pause: играет с ползунка, а по паузе оставляет ползунок
  /// там, где аудио остановилось.
  Future<void> togglePlay() async {
    final current = state.value;
    if (current == null) return;
    final player = _player;
    // Сверяемся со своим состоянием, а не с `player.playing`: у доигравшего до
    // конца плеера тот остаётся поднятым.
    if (current.isPlaying) {
      await player.pause();
      await seek(player.position.inMilliseconds);
      return;
    }
    // Источник ставим один раз: файл на весь экран один и тот же.
    if (player.audioSource == null) {
      await player.setFilePath(current.lesson.audioPath);
    }
    await player.seek(Duration(milliseconds: current.playheadMs));
    // play() завершается только по окончании воспроизведения — не ждём его.
    unawaited(player.play());
  }

  /// Сохраняет правки и обновляет список уроков.
  Future<void> save() async {
    final current = state.value;
    if (current == null || !current.canSave) return;
    state = AsyncValue.data(current.copyWith(isSaving: true));
    try {
      await ref.read(updateLessonContentProvider)(
        lessonId: lessonId,
        title: current.title,
        rawText: current.text,
        boundaries: current.boundaries,
      );
      ref.invalidate(lessonsControllerProvider);
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isSaving: false));
      rethrow;
    }
  }
}

final editLessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<EditLessonController, EditLessonState, String>(
      EditLessonController.new,
    );
