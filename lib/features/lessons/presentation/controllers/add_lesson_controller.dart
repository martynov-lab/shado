import 'package:dio/dio.dart';
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
    this.audioId,
    this.audioFileName,
    this.durationMs = 0,
    this.trim = const AudioTrim.full(0),
    this.pendingTrim,
    this.boundaries = const [],
    this.isUploading = false,
    this.uploadProgress = 0,
    this.isSubmitting = false,
  });

  final String title;
  final String text;

  /// Аудио, принятое сервером; `null` — файл ещё не выбран или не загружен.
  final String? audioId;

  final String? audioFileName;

  /// Длительность выбранного файла по версии сервера; `0` — файла ещё нет.
  final int durationMs;

  /// Отрезок файла, оставленный обрезкой. Пока не обрезали — файл целиком.
  final AudioTrim trim;

  /// Отрезок, который метки обрезки показывают прямо сейчас. `null` — обрезка
  /// не идёт.
  final AudioTrim? pendingTrim;

  /// Разметка кусков на волне, `N + 1` значение. Пуста, пока нет либо текста,
  /// либо аудио.
  final List<int> boundaries;

  /// Идёт отправка файла на сервер.
  final bool isUploading;

  /// Доля отправленного, `0..1`.
  final double uploadProgress;

  final bool isSubmitting;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  /// Волну показываем, когда есть что показывать: файл загружен и разобран.
  bool get hasWaveform => audioId != null && durationMs > 0;

  bool get isTrimming => pendingTrim != null;

  /// Что сейчас в окне волны: во время обрезки — файл целиком, чтобы обрезанное
  /// можно было вернуть обратно.
  AudioTrim get view => isTrimming ? AudioTrim.full(durationMs) : trim;

  bool get canSubmit =>
      !isSubmitting &&
      !isUploading &&
      // Незавершённая обрезка — сначала «Применить» или «Отменить».
      !isTrimming &&
      title.trim().isNotEmpty &&
      segmentCount > 0 &&
      audioId != null;

  AddLessonFormState copyWith({
    String? title,
    String? text,
    String? audioId,
    bool clearAudio = false,
    String? audioFileName,
    int? durationMs,
    AudioTrim? trim,
    AudioTrim? pendingTrim,
    bool clearPendingTrim = false,
    List<int>? boundaries,
    bool? isUploading,
    double? uploadProgress,
    bool? isSubmitting,
  }) {
    return AddLessonFormState(
      title: title ?? this.title,
      text: text ?? this.text,
      audioId: clearAudio ? null : (audioId ?? this.audioId),
      audioFileName: clearAudio
          ? null
          : (audioFileName ?? this.audioFileName),
      durationMs: durationMs ?? this.durationMs,
      trim: trim ?? this.trim,
      pendingTrim: clearPendingTrim ? null : (pendingTrim ?? this.pendingTrim),
      boundaries: boundaries ?? this.boundaries,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AddLessonController extends Notifier<AddLessonFormState> {
  /// Позволяет прервать долгую загрузку — на 50 МБ это не мгновение.
  CancelToken? _uploadCancel;

  @override
  AddLessonFormState build() {
    ref.onDispose(() => _uploadCancel?.cancel());
    return const AddLessonFormState();
  }

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

  // --- Аудио -----------------------------------------------------------------

  /// Выбирает файл и сразу отправляет его на сервер.
  ///
  /// Длительность и пики считает сервер, поэтому до ответа волны нет — зато
  /// после него не нужен ни локальный замер, ни собственный декодер.
  /// Возвращает `true`, если файл выбран.
  Future<bool> pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedAudioExtensions,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return false;
    final name = result!.files.single.name;

    _uploadCancel?.cancel();
    final cancelToken = _uploadCancel = CancelToken();
    state = state.copyWith(
      clearAudio: true,
      audioFileName: name,
      durationMs: 0,
      trim: const AudioTrim.full(0),
      clearPendingTrim: true,
      boundaries: const [],
      isUploading: true,
      uploadProgress: 0,
    );

    try {
      final upload = await ref.read(uploadAudioProvider)(
        filePath: path,
        cancel: cancelToken,
        onProgress: (sent, total) {
          // Пока файл летел, могли выбрать другой — тот прогресс уже не наш.
          if (_uploadCancel != cancelToken || total <= 0) return;
          state = state.copyWith(uploadProgress: sent / total);
        },
      );
      if (_uploadCancel != cancelToken) return true;
      final next = state.copyWith(
        audioId: upload.audioId,
        durationMs: upload.durationMs,
        // Новый файл приходит необрезанным.
        trim: AudioTrim.full(upload.durationMs),
        isUploading: false,
        uploadProgress: 1,
      );
      state = next.copyWith(boundaries: _fitBoundaries(next));
    } catch (_) {
      if (_uploadCancel == cancelToken) {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 0,
          durationMs: 0,
          clearAudio: true,
        );
      }
      rethrow;
    } finally {
      if (_uploadCancel == cancelToken) _uploadCancel = null;
    }
    return true;
  }

  /// Прерывает загрузку: файл остаётся невыбранным.
  void cancelUpload() {
    _uploadCancel?.cancel();
    _uploadCancel = null;
    state = state.copyWith(
      isUploading: false,
      uploadProgress: 0,
      durationMs: 0,
      clearAudio: true,
    );
  }

  /// Создаёт урок и обновляет список на главной.
  Future<Lesson> submit() async {
    final audioId = state.audioId;
    if (audioId == null) {
      throw StateError('Файл ещё не загружен');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final lesson = await ref.read(createLessonProvider)(
        CreateLessonParams(
          title: state.title,
          rawText: state.text,
          audioId: audioId,
          durationMs: state.durationMs,
          boundaries: state.boundaries.isEmpty ? null : state.boundaries,
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
