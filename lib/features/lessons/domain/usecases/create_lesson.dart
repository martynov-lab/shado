import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/audio_trim.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

class CreateLessonParams {
  const CreateLessonParams({
    required this.title,
    required this.rawText,
    required this.sourceAudioPath,
    this.boundaries,
    this.trim,
  });

  final String title;

  /// Текст целиком, куски разделены [kSegmentDelimiter].
  final String rawText;
  final String sourceAudioPath;

  /// Границы, размеченные на волне до создания урока (`N + 1` значение).
  /// `null` — разложить куски равномерно.
  final List<int>? boundaries;

  /// Отрезок аудио, оставленный обрезкой. `null` — файл целиком.
  final AudioTrim? trim;
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
    final boundaries = params.boundaries;
    return _repository.createLesson(
      title: title,
      sourceAudioPath: params.sourceAudioPath,
      segmentTexts: segmentTexts,
      // Разметка с экрана создания годится, только если она про этот же набор
      // кусков: текст могли поправить после перетаскивания меток.
      boundaries: boundaries != null && boundaries.length == segmentTexts.length + 1
          ? boundaries
          : null,
      trim: params.trim,
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
