import '../../domain/entities/folder.dart';
import '../screens/lessons/lesson_list_item.dart';

/// One row of the lesson list. Rows are described up front so the list can
/// build the widgets lazily.
sealed class LessonsListEntry {
  const LessonsListEntry();

  /// Folders first (with their header), then lessons separated by dividers.
  static List<LessonsListEntry> build({
    required List<LessonListItem> items,
    required List<Folder> folders,
    required bool showFolders,
  }) => [
    if (showFolders) ...[
      const FoldersHeaderEntry(),
      for (final folder in folders) FolderEntry(folder),
      if (items.isNotEmpty) const DividerEntry(),
    ],
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const DividerEntry(),
      LessonEntry(items[i]),
    ],
  ];
}

class FoldersHeaderEntry extends LessonsListEntry {
  const FoldersHeaderEntry();
}

class FolderEntry extends LessonsListEntry {
  const FolderEntry(this.folder);

  final Folder folder;
}

class DividerEntry extends LessonsListEntry {
  const DividerEntry();
}

class LessonEntry extends LessonsListEntry {
  const LessonEntry(this.item);

  final LessonListItem item;
}
