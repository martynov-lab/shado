import 'lesson.dart';

/// Folder — a lesson collection made by an author.
class Folder {
  const Folder({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.lessonCount,
    this.isPublic = true,
    this.lessons = const [],
  });

  final String id;
  final String title;

  /// Folder visibility; a private one is visible to its author only.
  final bool isPublic;

  bool get isPrivate => !isPublic;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Aggregate version; sent back in `If-Match` on edits.
  final int version;

  /// Number of lessons visible to the viewer.
  final int lessonCount;

  /// Folder lessons in insertion order; empty in the folder list.
  final List<Lesson> lessons;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder &&
          other.id == id &&
          other.title == title &&
          other.isPublic == isPublic &&
          other.version == version &&
          other.lessonCount == lessonCount;

  @override
  int get hashCode =>
      Object.hash(id, title, isPublic, version, lessonCount);

  @override
  String toString() => 'Folder($id, "$title", $lessonCount уроков)';
}
