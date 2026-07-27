import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

class CreateLessonParams {
  const CreateLessonParams({
    required this.title,
    required this.rawText,
    required this.sourceAudioPath,
  });

  final String title;

  /// Текст целиком, куски разделены [kSegmentDelimiter].
  final String rawText;
  final String sourceAudioPath;
}

/// Создание урока: разбиение текста на куски и передача их репозиторию,
/// который импортирует аудио и расставит равномерные границы.
class CreateLesson {
  const CreateLesson(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call(CreateLessonParams params) {
    final title = params.title.trim();
    if (title.isEmpty) {
      throw const ValidationFailure('Введите название урока');
    }
    if (params.sourceAudioPath.trim().isEmpty) {
      throw const ValidationFailure('Выберите аудиофайл');
    }
    final segmentTexts = splitIntoSegments(params.rawText);
    if (segmentTexts.isEmpty) {
      throw const ValidationFailure('Текст не содержит ни одного куска');
    }
    return _repository.createLesson(
      title: title,
      sourceAudioPath: params.sourceAudioPath,
      segmentTexts: segmentTexts,
    );
  }

  /// Разбивает текст по [kSegmentDelimiter], обрезает пробелы и выбрасывает
  /// пустые куски.
  static List<String> splitIntoSegments(String rawText) {
    return rawText
        .split(kSegmentDelimiter)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }
}
