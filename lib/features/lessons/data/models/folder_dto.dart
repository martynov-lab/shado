import '../../domain/entities/folder.dart';
import 'lesson_dto.dart';

/// Folder exactly as the server returns it.
class FolderDto {
  const FolderDto({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.lessonCount,
    this.isPublic = true,
    this.deletedAt,
    this.lessons = const [],
  });

  factory FolderDto.fromJson(Map<String, dynamic> json) => FolderDto(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    createdAt: _parseTime(json['created_at']),
    updatedAt: _parseTime(json['updated_at']),
    deletedAt: json['deleted_at'] == null
        ? null
        : _parseTime(json['deleted_at']),
    version: (json['version'] as num?)?.toInt() ?? 1,
    isPublic: json['is_public'] as bool? ?? true,
    lessonCount: (json['lesson_count'] as num?)?.toInt() ?? 0,
    lessons: [
      for (final lesson in (json['lessons'] as List<dynamic>? ?? const []))
        LessonDto.fromJson(lesson as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Deletion time; only present in a delta.
  final DateTime? deletedAt;

  final int version;
  final bool isPublic;
  final int lessonCount;
  final List<LessonDto> lessons;

  bool get isDeleted => deletedAt != null;

  /// Domain folder; its lessons have an empty `audioPath`.
  Folder toEntity() => Folder(
    id: id,
    title: title,
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: version,
    isPublic: isPublic,
    lessonCount: lessonCount,
    lessons: [for (final lesson in lessons) lesson.toEntity(audioPath: '')],
  );

  static DateTime _parseTime(Object? raw) =>
      DateTime.tryParse(raw as String? ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
