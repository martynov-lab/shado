import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import 'folder_grid_card.dart';
import 'lesson_grid_card.dart';

/// Card grid with pull-to-refresh; folders come first.
class LessonsGridView extends StatelessWidget {
  const LessonsGridView({
    super.key,
    required this.lessons,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
  });

  final List<Lesson> lessons;
  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;

  final List<Folder> folders;
  final void Function(Folder)? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final total = folders.length + lessons.length;

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
          final lesson = lessons[index - folders.length];
          return LessonGridCard(
            lesson: lesson,
            onTap: () => onOpen(lesson),
            onDelete: () => onDelete(lesson),
          );
        },
      ),
    );
  }
}
