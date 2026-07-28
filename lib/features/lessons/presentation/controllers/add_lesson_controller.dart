import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import 'lesson_providers.dart';
import 'lessons_controller.dart';

/// Состояние формы создания урока.
class AddLessonFormState {
  const AddLessonFormState({
    this.title = '',
    this.text = '',
    this.audioPath,
    this.audioFileName,
    this.durationMs = 0,
    this.trim = const AudioTrim.full(0),
    this.pendingTrim,
    this.boundaries = const [],
    this.isProbingAudio = false,
    this.isSubmitting = false,
  });

  final String title;
  final String text;
  final String? audioPath;
  final String? audioFileName;

  /// Длительность выбранного файла; `0` — файл ещё не разобран.
  final int durationMs;

  /// Отрезок файла, оставленный обрезкой. Пока не обрезали — файл целиком.
  final AudioTrim trim;

  /// Отрезок, который метки обрезки показывают прямо сейчас. `null` — обрезка
  /// не идёт.
  final AudioTrim? pendingTrim;

  /// Разметка кусков на волне, `N + 1` значение. Пуста, пока нет либо текста,
  /// либо аудио.
  final List<int> boundaries;

  final bool isProbingAudio;
  final bool isSubmitting;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  /// Волну показываем, когда есть что показывать: файл выбран и разобран.
  bool get hasWaveform => audioPath != null && durationMs > 0;

  bool get isTrimming => pendingTrim != null;

  /// Что сейчас в окне волны: во время обрезки — файл целиком, чтобы обрезанное
  /// можно было вернуть обратно.
  AudioTrim get view => isTrimming ? AudioTrim.full(durationMs) : trim;

  bool get canSubmit =>
      !isSubmitting &&
      !isProbingAudio &&
      // Незавершённая обрезка — сначала «Применить» или «Отменить».
      !isTrimming &&
      title.trim().isNotEmpty &&
      segmentCount > 0 &&
      audioPath != null;

  AddLessonFormState copyWith({
    String? title,
    String? text,
    String? audioPath,
    String? audioFileName,
    int? durationMs,
    AudioTrim? trim,
    AudioTrim? pendingTrim,
    bool clearPendingTrim = false,
    List<int>? boundaries,
    bool? isProbingAudio,
    bool? isSubmitting,
  }) {
    return AddLessonFormState(
      title: title ?? this.title,
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      audioFileName: audioFileName ?? this.audioFileName,
      durationMs: durationMs ?? this.durationMs,
      trim: trim ?? this.trim,
      pendingTrim: clearPendingTrim ? null : (pendingTrim ?? this.pendingTrim),
      boundaries: boundaries ?? this.boundaries,
      isProbingAudio: isProbingAudio ?? this.isProbingAudio,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AddLessonController extends Notifier<AddLessonFormState> {
  @override
  AddLessonFormState build() => const AddLessonFormState();

  void setTitle(String title) => state = state.copyWith(title: title);

  /// Текст задаёт число кусков, поэтому разметка подстраивается под него.
  void setText(String text) {
    final next = state.copyWith(text: text);
    state = next.copyWith(boundaries: _fitBoundaries(next));
  }

  void setBoundaries(List<int> boundaries) =>
      state = state.copyWith(boundaries: boundaries);

  void reset() => state = const AddLessonFormState();

  // --- Обрезка ---------------------------------------------------------------

  /// Включает режим обрезки: метки встают по краям того, что оставлено сейчас,
  /// а в окно возвращается файл целиком — отрезанное можно вернуть.
  void startTrim() {
    if (!state.hasWaveform || state.isTrimming) return;
    state = state.copyWith(pendingTrim: state.trim);
  }

  void updateTrim(AudioTrim trim) {
    if (!state.isTrimming) return;
    state = state.copyWith(pendingTrim: trim);
  }

  void cancelTrim() => state = state.copyWith(clearPendingTrim: true);

  /// Применяет обрезку: метки кусков переезжают внутрь нового отрезка, дальше
  /// урок размечают уже по нему.
  void applyTrim() {
    final pending = state.pendingTrim;
    if (pending == null) return;
    final next = state.copyWith(trim: pending, clearPendingTrim: true);
    state = next.copyWith(
      // Число кусков обрезка не меняет — двигаются только сами метки. Разметка,
      // отставшая от текста, всё равно разложится заново.
      boundaries: next.boundaries.length == next.segmentCount + 1
          ? SegmentBoundaries.refit(next.boundaries, next.trim)
          : _fitBoundaries(next),
    );
  }

  /// Подгоняет разметку под текущие текст и обрезку.
  List<int> _fitBoundaries(AddLessonFormState form) {
    if (form.durationMs <= 0 || form.segmentCount == 0) return const [];
    return SegmentBoundaries.resize(
      form.boundaries,
      form.segmentCount,
      form.trim,
    );
  }

  /// Возвращает `true`, если файл выбран.
  ///
  /// Длительность читается сразу: без неё нельзя показать волну с метками.
  Future<bool> pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedAudioExtensions,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return false;
    state = state.copyWith(
      audioPath: path,
      audioFileName: result!.files.single.name,
      durationMs: 0,
      trim: const AudioTrim.full(0),
      clearPendingTrim: true,
      boundaries: const [],
      isProbingAudio: true,
    );
    try {
      final durationMs = await ref.read(getAudioDurationProvider)(path);
      // Пока файл разбирался, могли выбрать другой — тот ответ уже не нужен.
      if (state.audioPath != path) return true;
      final next = state.copyWith(
        durationMs: durationMs,
        // Новый файл приходит необрезанным.
        trim: AudioTrim.full(durationMs),
        isProbingAudio: false,
      );
      state = next.copyWith(boundaries: _fitBoundaries(next));
    } catch (_) {
      if (state.audioPath == path) {
        state = state.copyWith(isProbingAudio: false, durationMs: 0);
      }
      rethrow;
    }
    return true;
  }

  /// Создаёт урок и обновляет список на главной.
  Future<Lesson> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final lesson = await ref.read(createLessonProvider)(
        CreateLessonParams(
          title: state.title,
          rawText: state.text,
          sourceAudioPath: state.audioPath ?? '',
          boundaries: state.boundaries.isEmpty ? null : state.boundaries,
          trim: state.trim,
        ),
      );
      ref.invalidate(lessonsControllerProvider);
      state = const AddLessonFormState();
      return lesson;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final addLessonControllerProvider =
    NotifierProvider<AddLessonController, AddLessonFormState>(
      AddLessonController.new,
    );
