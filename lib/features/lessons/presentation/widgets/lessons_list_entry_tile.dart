import 'package:flutter/material.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import 'folder_list_row.dart';
import 'folders_section_header.dart';
import 'lesson_list_row.dart';
import 'lesson_row_divider.dart';
import 'lessons_list_entry.dart';

/// Draws one row of the lesson list.
class LessonsListEntryTile extends StatelessWidget {
  const LessonsListEntryTile({
    super.key,
    required this.entry,
    required this.onOpen,
    required this.onDelete,
    this.onOpenFolder,
    this.onCreateFolder,
  });

  final LessonsListEntry entry;
  final ValueChanged<Lesson> onOpen;
  final ValueChanged<Lesson> onDelete;
  final ValueChanged<Folder>? onOpenFolder;
  final VoidCallback? onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      FoldersHeaderEntry() => FoldersSectionHeader(onCreate: onCreateFolder),
      FolderEntry(:final folder) => FolderListRow(
        folder: folder,
        onTap: () => onOpenFolder?.call(folder),
      ),
      DividerEntry() => const LessonRowDivider(),
      LessonEntry(:final item) => LessonListRow(
        lesson: item.lesson,
        progress: item.progress,
        canDelete: item.canModify,
        onTap: () => onOpen(item.lesson),
        onDelete: () => onDelete(item.lesson),
      ),
    };
  }
}
