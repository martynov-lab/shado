import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../screens/lessons/lesson_list_item.dart';
import 'folder_grid_card.dart';
import 'lesson_grid_card.dart';

/// Card grid with pull-to-refresh; folders come first.
class LessonsGridView extends StatelessWidget {
  const LessonsGridView({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
  });

  final List<LessonListItem> items;
  final ValueChanged<Lesson> onOpen;
  final ValueChanged<Lesson> onDelete;
  final Future<void> Function() onRefresh;

  final List<Folder> folders;
  final ValueChanged<Folder>? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final total = folders.length + items.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.s4,
          mainAxisSpacing: AppSpacing.s4,
          mainAxisExtent: 200,
        ),
        itemCount: total,
        itemBuilder: (context, index) {
          if (index < folders.length) {
            final folder = folders[index];
            return FolderGridCard(
              folder: folder,
              onTap: () => onOpenFolder?.call(folder),
            );
          }
          final item = items[index - folders.length];
          return LessonGridCard(
            lesson: item.lesson,
            progress: item.progress,
            canDelete: item.canModify,
            onTap: () => onOpen(item.lesson),
            onDelete: () => onDelete(item.lesson),
          );
        },
      ),
    );
  }
}
