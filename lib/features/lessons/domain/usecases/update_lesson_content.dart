import '../../../../core/error/failures.dart';
import '../entities/audio_trim.dart';
import '../entities/lesson.dart';
import '../entities/segment_boundaries.dart';
import '../repositories/lesson_repository.dart';
import 'create_lesson.dart';

/// Правка уже созданного урока: название, разбивка текста на куски, границы
/// этих кусков на аудио и обрезка.
///
/// Число кусков может измениться, поэтому урок пересобирается целиком. Сам
/// аудиофайл не трогаем: он иммутабелен и общий для всех уроков, которые на
/// него ссылаются.
class UpdateLessonContent {
  const UpdateLessonContent(this._repository);

  final LessonRepository _repository;

  /// [lesson] — то, что правим: экран правки уже держит его у себя, и
  /// перечитывать урок по сети ради этого незачем.
  Future<Lesson> call({
    required Lesson lesson,
    required String title,
    required String rawText,
    required List<int> boundaries,
    AudioTrim? trim,
    bool? isPublic,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ValidationFailure('Введите название урока');
    }
    final segmentTexts = CreateLesson.splitIntoSegments(rawText);
    if (segmentTexts.isEmpty) {
      throw const ValidationFailure('Текст не содержит ни одного куска');
    }
    final range = (trim ?? lesson.trim).clampedTo(lesson.durationMs);
    // Разметка могла отстать от текста — тогда куски раскладываются заново.
    final source = boundaries.length == segmentTexts.length + 1
        ? boundaries
        : SegmentBoundaries.resize(boundaries, segmentTexts.length, range);
    final updated = lesson
        // Публичность обновляем только когда её задал автор (owner); иначе
        // copyWith сохраняет прежнее значение.
        .copyWith(title: trimmedTitle, isPublic: isPublic)
        .withSegments(
          texts: segmentTexts,
          boundaries: SegmentBoundaries.normalize(source, range),
        );
    await _repository.updateLesson(updated, isPublic: isPublic);
    return updated;
  }
}
