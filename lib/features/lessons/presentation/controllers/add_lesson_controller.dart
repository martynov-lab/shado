import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import '../widgets/segment_splitter/segment_boundary_math.dart' as marks;
import 'lesson_providers.dart';
import 'lessons_controller.dart';

/// Состояние формы создания урока.
class AddLessonFormState {
  const AddLessonFormState({
    this.title = '',
    this.text = '',
    this.accent,
    this.level,
    this.topicId,
    this.audioId,
    this.audioPath,
    this.audioFileName,
    this.durationMs = 0,
    this.trim = const AudioTrim.full(0),
    this.pendingTrim,
    this.boundaries = const [],
    this.isPublic = true,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.isSubmitting = false,
  });

  final String title;
  final String text;

  /// Акцент и уровень — обязательный выбор (§6). `null` — ещё не выбрали, и
  /// урок отправлять нельзя.
  final LessonAccent? accent;
  final LessonLevel? level;

  /// Тема из справочника; `null` — «без темы», сервер поставит свою.
  final String? topicId;

  /// Аудио, принятое сервером; `null` — файл ещё не выбран или не загружен.
  final String? audioId;

  /// Копия файла в кеше приложения: её играет плеер экрана, чтобы метки можно
  /// было расставлять на слух до сохранения урока.
  final String? audioPath;

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

  /// Публичность урока — тумблером управляет только owner. Для остальных
  /// авторов значение вычисляется по роли в [AddLessonController.submit].
  final bool isPublic;

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
      audioId != null &&
      // Без акцента и уровня сервер ответит `422` — не даём и пробовать.
      accent != null &&
      level != null;

  AddLessonFormState copyWith({
    String? title,
    String? text,
    LessonAccent? accent,
    LessonLevel? level,
    String? topicId,
    bool clearTopic = false,
    String? audioId,
    String? audioPath,
    bool clearAudio = false,
    String? audioFileName,
    int? durationMs,
    AudioTrim? trim,
    AudioTrim? pendingTrim,
    bool clearPendingTrim = false,
    List<int>? boundaries,
    bool? isPublic,
    bool? isUploading,
    double? uploadProgress,
    bool? isSubmitting,
  }) {
    return AddLessonFormState(
      title: title ?? this.title,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      level: level ?? this.level,
      topicId: clearTopic ? null : (topicId ?? this.topicId),
      audioId: clearAudio ? null : (audioId ?? this.audioId),
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      audioFileName: clearAudio ? null : (audioFileName ?? this.audioFileName),
      durationMs: durationMs ?? this.durationMs,
      trim: trim ?? this.trim,
      pendingTrim: clearPendingTrim ? null : (pendingTrim ?? this.pendingTrim),
      boundaries: boundaries ?? this.boundaries,
      isPublic: isPublic ?? this.isPublic,
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

  /// Ставит новую метку №[ordinal] (1-based) в тексте, а парную ей границу — в
  /// текущую позицию плеера [playheadMs].
  ///
  /// Так границы расставляют на слух: доводят плеер до паузы между фразами и
  /// ставят в этом месте метку. Если плеер оказался перед предыдущей меткой
  /// (аудио ещё не играли — ползунок в самом начале), граница встаёт вплотную к
  /// ней. Пока нет аудио, разметки ещё нет — фиксируем только текст.
  void insertMarker(String text, int ordinal, int playheadMs) {
    final boundaries = state.boundaries;
    final inSync = boundaries.length == state.segmentCount + 1;
    final next = state.copyWith(text: text);
    if (!inSync) {
      state = next.copyWith(boundaries: _fitBoundaries(next));
      return;
    }
    // Края разметки прибиты к границам оставленного отрезка — внутри них и
    // сажаем метку.
    final span = AudioTrim(startMs: boundaries.first, endMs: boundaries.last);
    state = next.copyWith(
      boundaries: SegmentBoundaries.insertAt(
        boundaries,
        ordinal,
        playheadMs,
        span,
      ),
    );
  }

  /// Убирает метку №[ordinal] (1-based) сразу из текста и с волны: исчезает и
  /// разделитель, и парная ему граница `boundaries[ordinal]`. Остальные границы
  /// остаются на местах — в отличие от [setText], который переразбил бы хвост.
  void removeMarker(int ordinal) {
    final indices = marks.markerIndices(state.text);
    if (ordinal < 1 || ordinal > indices.length) return;
    final nextText = marks.removeMarker(state.text, indices[ordinal - 1]);
    final boundaries = state.boundaries;
    final inSync = boundaries.length == state.segmentCount + 1;
    final next = state.copyWith(text: nextText);
    state = next.copyWith(
      boundaries: inSync && ordinal < boundaries.length - 1
          ? ([...boundaries]..removeAt(ordinal))
          : _fitBoundaries(next),
    );
  }

  void setAccent(LessonAccent? accent) =>
      state = state.copyWith(accent: accent);

  void setLevel(LessonLevel? level) => state = state.copyWith(level: level);

  /// Тумблер «Приватный урок» (только для owner): `true` — урок приватный.
  void setPrivate(bool isPrivate) =>
      state = state.copyWith(isPublic: !isPrivate);

  /// `null` — «без темы»: сервер поставит уроку тему по умолчанию.
  void setTopic(String? topicId) => state = topicId == null
      ? state.copyWith(clearTopic: true)
      : state.copyWith(topicId: topicId);

  /// Убирает выбранную тему, если её больше нет в справочнике: пока форму
  /// заполняли, тему могли удалить на другом устройстве.
  void dropTopicUnless(Iterable<String> availableIds) {
    final selected = state.topicId;
    if (selected == null || availableIds.contains(selected)) return;
    state = state.copyWith(clearTopic: true);
  }

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
        audioPath: upload.localPath.isEmpty ? null : upload.localPath,
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
    final accent = state.accent;
    final level = state.level;
    if (accent == null || level == null) {
      throw StateError('Акцент и уровень не выбраны');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final lesson = await ref.read(createLessonProvider)(
        CreateLessonParams(
          title: state.title,
          rawText: state.text,
          audioId: audioId,
          durationMs: state.durationMs,
          accent: accent,
          level: level,
          topicId: state.topicId,
          boundaries: state.boundaries.isEmpty ? null : state.boundaries,
          isPublic: _isPublicForRole(),
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

  /// Публичность урока для отправки, по роли автора:
  /// owner управляет тумблером, user-pro всегда приватен, для остальных
  /// (admin) решает сервер — ключ не шлём.
  bool? _isPublicForRole() {
    final role = ref.read(authControllerProvider).user?.role;
    return switch (role) {
      UserRole.owner => state.isPublic,
      UserRole.userPro => false,
      _ => null,
    };
  }
}

final addLessonControllerProvider =
    NotifierProvider<AddLessonController, AddLessonFormState>(
      AddLessonController.new,
    );
