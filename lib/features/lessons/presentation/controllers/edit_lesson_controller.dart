import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import '../widgets/segment_splitter/segment_boundary_math.dart' as marks;
import 'lesson_providers.dart';
import 'lessons_controller.dart';
import 'library_controller.dart';

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
    required this.isPublic,
    this.pendingTrim,
    this.playheadMs = 0,
    this.isPlaying = false,
    this.isSaving = false,
  });

  final Lesson lesson;
  final String title;
  final String text;
  final List<int> boundaries;

  /// Публичность урока — тумблером управляет только owner. Начальное значение
  /// берётся из урока.
  final bool isPublic;

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
    bool? isPublic,
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
      isPublic: isPublic ?? this.isPublic,
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
      isPublic: lesson.isPublic,
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
      next.copyWith(boundaries: _resizeBoundaries(next)),
    );
  }

  void setBoundaries(List<int> boundaries) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(boundaries: boundaries));
  }

  /// Ставит новую метку №[ordinal] (1-based) в тексте, а парную ей границу — в
  /// текущую позицию плеера [playheadMs].
  ///
  /// Так границы расставляют на слух: доводят плеер до паузы между фразами и
  /// ставят в этом месте метку. Если плеер оказался перед предыдущей меткой
  /// (аудио ещё не играли — ползунок в самом начале), граница встаёт вплотную к
  /// ней.
  void insertMarker(String text, int ordinal, int playheadMs) {
    final current = state.value;
    if (current == null) return;
    final boundaries = current.boundaries;
    final next = current.copyWith(text: text);
    // Разметка отстала от текста — раскладываем её заново, как при обычном вводе.
    if (boundaries.length != current.segmentCount + 1) {
      state = AsyncValue.data(next.copyWith(boundaries: _resizeBoundaries(next)));
      return;
    }
    // Края разметки прибиты к границам оставленного отрезка — внутри них и
    // сажаем метку.
    final span = AudioTrim(startMs: boundaries.first, endMs: boundaries.last);
    state = AsyncValue.data(
      next.copyWith(
        boundaries: SegmentBoundaries.insertAt(
          boundaries,
          ordinal,
          playheadMs,
          span,
        ),
      ),
    );
  }

  /// Подгоняет разметку под текст и обрезку: пустой текст разметку не трогает.
  List<int> _resizeBoundaries(EditLessonState form) => form.segmentCount == 0
      ? form.boundaries
      : SegmentBoundaries.resize(form.boundaries, form.segmentCount, form.trim);

  /// Убирает метку №[ordinal] (1-based) сразу из текста и с волны: исчезает и
  /// разделитель, и парная ему граница `boundaries[ordinal]`. Остальные границы
  /// остаются на местах — в отличие от [setText], который переразбил бы хвост.
  void removeMarker(int ordinal) {
    final current = state.value;
    if (current == null) return;
    final indices = marks.markerIndices(current.text);
    if (ordinal < 1 || ordinal > indices.length) return;
    final nextText = marks.removeMarker(current.text, indices[ordinal - 1]);
    final boundaries = current.boundaries;
    final inSync = boundaries.length == current.segmentCount + 1;
    final nextBoundaries = inSync && ordinal < boundaries.length - 1
        ? ([...boundaries]..removeAt(ordinal))
        : SegmentBoundaries.resize(
            boundaries,
            CreateLesson.splitIntoSegments(nextText).length,
            current.trim,
          );
    state = AsyncValue.data(
      current.copyWith(text: nextText, boundaries: nextBoundaries),
    );
  }

  /// Тумблер «Приватный урок» (только для owner): `true` — урок приватный.
  void setPrivate(bool isPrivate) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isPublic: !isPrivate));
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
        isPublic: _isPublicForRole(current.isPublic),
      );
      ref.invalidate(lessonsControllerProvider);
      // Правка меняет и карточку в ленте — перечитываем корень.
      ref.invalidate(libraryControllerProvider);
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isSaving: false));
      rethrow;
    }
  }

  /// Публичность для отправки, по роли автора: owner управляет тумблером,
  /// user-pro всегда приватен, для остальных (admin) решает сервер.
  bool? _isPublicForRole(bool toggled) {
    final role = ref.read(authControllerProvider).user?.role;
    return switch (role) {
      UserRole.owner => toggled,
      UserRole.userPro => false,
      _ => null,
    };
  }
}

final editLessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<EditLessonController, EditLessonState, String>(
      EditLessonController.new,
    );
