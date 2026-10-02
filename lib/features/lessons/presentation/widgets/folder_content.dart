import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import 'folder_lesson_tile.dart';
import 'folder_top_bar.dart';
import 'lesson_labels.dart';

/// Open folder body: header, the add-lessons button and the lesson list.
class FolderContent extends StatelessWidget {
  const FolderContent({
    super.key,
    required this.folder,
    required this.canModify,
    required this.onBack,
    required this.onOpenLesson,
    required this.onRename,
    required this.onDelete,
    required this.onAddLessons,
    required this.onRemoveLesson,
    required this.onRefresh,
  });

  final Folder folder;
  final bool canModify;
  final VoidCallback onBack;
  final void Function(Lesson) onOpenLesson;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddLessons;
  final void Function(String lessonId) onRemoveLesson;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FolderTopBar(
          title: folder.title,
          onBack: onBack,
          onRename: canModify ? onRename : null,
          onDelete: canModify ? onDelete : null,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2,
                    vertical: AppSpacing.s2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lessonsLabel(folder.lessonCount),
                          style: AppText.caption.copyWith(color: colors.text3),
                        ),
                      ),
                      if (canModify)
                        AppButton(
                          label: 'Add lessons',
                          icon: Icons.add,
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.sm,
                          onPressed: onAddLessons,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                if (folder.lessons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s8,
                    ),
                    child: Text(
                      canModify
                          ? 'No lessons in this folder yet. Add them with the button above.'
                          : 'No lessons in this folder yet.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: colors.text2),
                    ),
                  )
                else
                  for (final lesson in folder.lessons)
                    FolderLessonTile(
                      lesson: lesson,
                      onOpen: () => onOpenLesson(lesson),
                      onRemove: canModify
                          ? () => onRemoveLesson(lesson.id)
                          : null,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
