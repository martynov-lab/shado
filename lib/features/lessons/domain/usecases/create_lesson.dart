import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

class CreateLessonParams {
  const CreateLessonParams({
    required this.title,
    required this.rawText,
    required this.audioId,
    required this.durationMs,
    this.boundaries,
  });

  final String title;

  /// Текст целиком, куски разделены [kSegmentDelimiter].
  final String rawText;

  /// Аудио, уже принятое сервером: загрузка идёт до создания урока.
  final String audioId;

  /// Длительность файла по версии сервера — он же её и считал.
  final int durationMs;

  /// Границы, размеченные на волне до создания урока (`N + 1` значение).
  /// `null` — разложить куски равномерно.
  final List<int>? boundaries;
}

/// Создание урока: разбиение текста на куски и передача их репозиторию,
/// который отправит урок на сервер и положит в кеш.
class CreateLesson {
  const CreateLesson(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call(CreateLessonParams params) {
    final title = params.title.trim();
    if (title.isEmpty) {
      throw const ValidationFailure('Введите название урока');
    }
    if (params.audioId.trim().isEmpty) {
      throw const ValidationFailure('Выберите аудиофайл');
    }
    if (params.durationMs <= 0) {
      throw const ValidationFailure(
        'Длительность аудио должна быть больше нуля',
      );
    }
    final segmentTexts = splitIntoSegments(params.rawText);
    if (segmentTexts.isEmpty) {
      throw const ValidationFailure('Текст не содержит ни одного куска');
    }
    final boundaries = params.boundaries;
    return _repository.createLesson(
      title: title,
      audioId: params.audioId,
      durationMs: params.durationMs,
      segmentTexts: segmentTexts,
      // Разметка с экрана создания годится, только если она про этот же набор
      // кусков: текст могли поправить после перетаскивания меток.
      boundaries:
          boundaries != null && boundaries.length == segmentTexts.length + 1
          ? boundaries
          : null,
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
