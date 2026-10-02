import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../screens/lessons/lesson_list_item.dart';
import 'lessons_list_entry.dart';
import 'lessons_list_entry_tile.dart';

/// Lesson list with pull-to-refresh; the folder section shares the scroll.
class LessonsListView extends StatelessWidget {
  const LessonsListView({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
    this.onCreateFolder,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.s4),
  });

  final List<LessonListItem> items;
  final ValueChanged<Lesson> onOpen;
  final ValueChanged<Lesson> onDelete;
  final Future<void> Function() onRefresh;

  /// Folders shown above the lesson list.
  final List<Folder> folders;
  final ValueChanged<Folder>? onOpenFolder;

  /// Creates a folder; `null` hides the button from non-authors.
  final VoidCallback? onCreateFolder;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final entries = LessonsListEntry.build(
      items: items,
      folders: folders,
      showFolders: folders.isNotEmpty || onCreateFolder != null,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: padding,
        itemCount: entries.length,
        itemBuilder: (context, index) => LessonsListEntryTile(
          entry: entries[index],
          onOpen: onOpen,
          onDelete: onDelete,
          onOpenFolder: onOpenFolder,
          onCreateFolder: onCreateFolder,
        ),
      ),
    );
  }
}
