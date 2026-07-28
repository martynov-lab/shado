import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/segment_boundaries.dart';
import '../../domain/usecases/create_lesson.dart';
import 'lesson_providers.dart';
import 'lessons_controller.dart';

/// Состояние экрана правки урока: та же разметка, что и при создании, но
/// поверх уже импортированного аудио.
class EditLessonState {
  const EditLessonState({
    required this.lesson,
    required this.title,
    required this.text,
    required this.boundaries,
    this.isSaving = false,
  });

  final Lesson lesson;
  final String title;
  final String text;
  final List<int> boundaries;
  final bool isSaving;

  int get segmentCount => CreateLesson.splitIntoSegments(text).length;

  bool get canSave => !isSaving && title.trim().isNotEmpty && segmentCount > 0;

  EditLessonState copyWith({
    String? title,
    String? text,
    List<int>? boundaries,
    bool? isSaving,
  }) {
    return EditLessonState(
      lesson: lesson,
      title: title ?? this.title,
      text: text ?? this.text,
      boundaries: boundaries ?? this.boundaries,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Правка урока: разбивка текста и границы кусков на волне.
class EditLessonController extends AsyncNotifier<EditLessonState> {
  EditLessonController(this.lessonId);

  final String lessonId;

  @override
  Future<EditLessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    return EditLessonState(
      lesson: lesson,
      title: lesson.title,
      text: initialText(lesson),
      boundaries: lesson.boundaries,
    );
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
