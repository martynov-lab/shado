import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/lesson.dart';
import '../entities/lesson_category.dart';
import '../repositories/lesson_repository.dart';

class CreateLessonParams {
  const CreateLessonParams({
    required this.title,
    required this.rawText,
    required this.audioId,
    required this.durationMs,
    required this.accent,
    required this.level,
    this.topicId,
    this.boundaries,
    this.isPublic,
  });

  final String title;

  /// The whole text with segments split by [kSegmentDelimiter].
  final String rawText;

  /// Audio already accepted by the server.
  final String audioId;

  /// File duration as reported by the server.
  final int durationMs;

  /// Accent and level are required choices.
  final LessonAccent accent;
  final LessonLevel level;

  /// Topic from the directory; `null` lets the server pick the default.
  final String? topicId;

  /// Boundaries marked on the waveform; `null` lays segments out evenly.
  final List<int>? boundaries;

  /// Lesson visibility; `null` lets the server decide.
  final bool? isPublic;
}

/// Lesson creation: splits the text into segments and passes them on.
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
      accent: params.accent,
      level: params.level,
      // The server treats an empty string as an unknown topic.
      topicId: (params.topicId?.isEmpty ?? true) ? null : params.topicId,
      // The layout only fits when it describes the same set of segments.
      boundaries:
          boundaries != null && boundaries.length == segmentTexts.length + 1
          ? boundaries
          : null,
      isPublic: params.isPublic,
    );
  }

  /// Splits text by [kSegmentDelimiter], trims spaces and drops empty
  /// segments.
  static List<String> splitIntoSegments(String rawText) {
    return rawText
        .split(kSegmentDelimiter)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }
}
