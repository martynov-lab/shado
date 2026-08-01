import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/audio_trim.dart';
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
    required this.trim,
    this.pendingTrim,
    this.playheadMs = 0,
    this.isPlaying = false,
    this.isSaving = false,
  });

  final Lesson lesson;
  final String title;
  final String text;
  final List<int> boundaries;

  /// Отрезок файла, оставленный обрезкой.
  final AudioTrim trim;

  /// Отрезок, который метки обрезки показывают прямо сейчас. `null` — обрезка
  /// не идёт.
  final AudioTrim? pendingTrim;

  /// Откуда играть: ползунок на волне, который перетаскивают вручную и на
  /// котором аудио останавливается по паузе. В миллисекундах файла.
  final int playheadMs;

  final bool isPlaying;
  final bool isSaving;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  bool get isTrimming => pendingTrim != null;

  /// Что сейчас в окне волны: во время обрезки — файл целиком, чтобы обрезанное
  /// можно было вернуть обратно.
  AudioTrim get view => isTrimming ? AudioTrim.full(lesson.durationMs) : trim;

  bool get canSave =>
      !isSaving &&
      // Незавершённая обрезка — сначала «Применить» или «Отменить».
      !isTrimming &&
      title.trim().isNotEmpty &&
      segmentCount > 0;

  EditLessonState copyWith({
    String? title,
    String? text,
    List<int>? boundaries,
    AudioTrim? trim,
    AudioTrim? pendingTrim,
    bool clearPendingTrim = false,
    int? playheadMs,
    bool? isPlaying,
    bool? isSaving,
  }) {
    return EditLessonState(
      lesson: lesson,
      title: title ?? this.title,
      text: text ?? this.text,
      boundaries: boundaries ?? this.boundaries,
      trim: trim ?? this.trim,
      pendingTrim: clearPendingTrim ? null : (pendingTrim ?? this.pendingTrim),
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
    final stateSubscription = player.playerStateStream.listen(_onPlayerState);
    ref.onDispose(stateSubscription.cancel);
    final positionSubscription = player.positionStream.listen(_onPosition);
    ref.onDispose(positionSubscription.cancel);
    return EditLessonState(
      lesson: lesson,
      title: lesson.title,
      text: initialText(lesson),
      boundaries: lesson.boundaries,
      trim: lesson.trim,
      // Урок начинается там, где кончается обрезанная голова.
      playheadMs: lesson.trim.startMs,
    );
  }

  /// Файл заряжен в плеер целиком, поэтому конец обрезанной дорожки стережём
  /// сами: дальше него аудио к уроку уже не относится.
  void _onPosition(Duration position) {
    final current = state.value;
    if (current == null || !current.isPlaying || current.isTrimming) return;
    if (position.inMilliseconds < current.trim.endMs) return;
    unawaited(_player.pause());
    unawaited(seek(current.trim.endMs));
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
                next.trim,
              ),
      ),
    );
  }

  void setBoundaries(List<int> boundaries) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(boundaries: boundaries));
  }

  // --- Обрезка ---------------------------------------------------------------

  /// Включает режим обрезки: метки встают по краям того, что оставлено сейчас,
  /// а в окно возвращается файл целиком — отрезанное можно вернуть.
  void startTrim() {
    final current = state.value;
    if (current == null || current.isTrimming) return;
    state = AsyncValue.data(current.copyWith(pendingTrim: current.trim));
  }

  void updateTrim(AudioTrim trim) {
    final current = state.value;
    if (current == null || !current.isTrimming) return;
    state = AsyncValue.data(current.copyWith(pendingTrim: trim));
  }

  Future<void> cancelTrim() async {
    final current = state.value;
    if (current == null || !current.isTrimming) return;
    state = AsyncValue.data(current.copyWith(clearPendingTrim: true));
    // Ползунок мог уехать в ту часть файла, которой в уроке нет.
    await seek(current.trim.clampMs(current.playheadMs));
  }

  /// Применяет обрезку: метки кусков переезжают внутрь нового отрезка, дальше
  /// урок размечают уже по нему.
  Future<void> applyTrim() async {
    final current = state.value;
    final pending = current?.pendingTrim;
    if (current == null || pending == null) return;
    state = AsyncValue.data(
      current.copyWith(
        trim: pending,
        clearPendingTrim: true,
        // Число кусков обрезка не меняет — двигаются только сами метки.
        // Разметка, отставшая от текста, всё равно разложится заново.
        boundaries: current.boundaries.length == current.segmentCount + 1
            ? SegmentBoundaries.refit(current.boundaries, pending)
            : SegmentBoundaries.resize(
                current.boundaries,
                current.segmentCount,
                pending,
              ),
      ),
    );
    await seek(pending.clampMs(current.playheadMs));
  }

  /// Ставит ползунок в заданное место аудио. Если оно играет, продолжает с
  /// новой точки, не прерываясь.
  ///
  /// Во время обрезки ползунок ходит по файлу целиком — иначе не послушать то,
  /// что собираются отрезать.
  Future<void> seek(int positionMs) async {
    final current = state.value;
    if (current == null) return;
    final clamped = current.isTrimming
        ? positionMs.clamp(0, current.lesson.durationMs)
        : current.trim.clampMs(positionMs);
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
    // С самого конца играть нечего — начинаем дорожку заново.
    await seek(
      !current.isTrimming && current.playheadMs >= current.trim.endMs
          ? current.trim.startMs
          : current.playheadMs,
    );
    // play() завершается только по окончании воспроизведения — не ждём его.
    unawaited(player.play());
  }

  /// Сохраняет правки и обновляет список уроков.
  ///
  /// Урок мог измениться на другом устройстве — тогда сервер отвечает
  /// конфликтом версий, а репозиторий кладёт свежую версию в кеш. Молча
  /// перезаписывать её нельзя, поэтому ошибка уходит наверх: экран покажет её
  /// и предложит переоткрыть урок.
  Future<void> save() async {
    final current = state.value;
    if (current == null || !current.canSave) return;
    state = AsyncValue.data(current.copyWith(isSaving: true));
    try {
      await ref.read(updateLessonContentProvider)(
        lesson: current.lesson,
        title: current.title,
        rawText: current.text,
        boundaries: current.boundaries,
        trim: current.trim,
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
