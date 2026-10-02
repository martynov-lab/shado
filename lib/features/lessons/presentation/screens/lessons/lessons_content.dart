import '../../../domain/entities/folder.dart';
import 'lesson_list_item.dart';

/// What the lessons screen lists after search and filters.
class LessonsContent {
  const LessonsContent({
    required this.items,
    required this.folders,
    required this.isLibraryEmpty,
  });

  final List<LessonListItem> items;
  final List<Folder> folders;

  /// Neither folders nor lessons: a placeholder replaces search and filters.
  final bool isLibraryEmpty;
}
