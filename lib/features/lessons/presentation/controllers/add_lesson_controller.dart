import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/lesson.dart';
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
    this.isSubmitting = false,
  });

  final String title;
  final String text;
  final String? audioPath;
  final String? audioFileName;
  final bool isSubmitting;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  bool get canSubmit =>
      !isSubmitting &&
      title.trim().isNotEmpty &&
      segmentCount > 0 &&
      audioPath != null;

  AddLessonFormState copyWith({
    String? title,
    String? text,
    String? audioPath,
    String? audioFileName,
    bool? isSubmitting,
  }) {
    return AddLessonFormState(
      title: title ?? this.title,
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      audioFileName: audioFileName ?? this.audioFileName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AddLessonController extends Notifier<AddLessonFormState> {
  @override
  AddLessonFormState build() => const AddLessonFormState();

  void setTitle(String title) => state = state.copyWith(title: title);

  void setText(String text) => state = state.copyWith(text: text);

  void reset() => state = const AddLessonFormState();

  /// Возвращает `true`, если файл выбран.
  Future<bool> pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: kAllowedAudioExtensions,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return false;
    state = state.copyWith(
      audioPath: path,
      audioFileName: result!.files.single.name,
    );
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
