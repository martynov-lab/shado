import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/library_root.dart';
import '../controllers/folder_controller.dart';
import '../controllers/lesson_permissions.dart';
import '../controllers/library_controller.dart';
import '../widgets/add_lessons_to_folder_sheet.dart';
import '../widgets/delete_folder_dialog.dart';
import '../widgets/folder_editor_dialog.dart';
import '../widgets/folder_lesson_tile.dart';
import '../widgets/lesson_labels.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'lesson_page.dart';

/// A single folder screen: its lessons, contents and metadata.
class FolderPage extends ConsumerWidget {
  const FolderPage({super.key, required this.folderId});

  /// Route template; [routeTo] builds a path to a specific folder.
  static const String routePath = '/folders/:id';

  static String routeTo(String folderId) => '/folders/$folderId';

  final String folderId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HomePage.routePath);
    }
  }

  void _openLesson(BuildContext context, Lesson lesson) =>
      context.push(LessonPage.routeTo(lesson.id));

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rename(
    BuildContext context,
    FolderDetailController controller,
    Folder folder,
  ) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => FolderEditorDialog(
        title: 'Переименовать папку',
        confirmLabel: 'Сохранить',
        initialValue: folder.title,
      ),
    );
    if (title == null) return;
    try {
      await controller.rename(title);
    } catch (error) {
      if (context.mounted) _showMessage(context, 'Не удалось сохранить: $error');
    }
  }

  Future<void> _delete(
    BuildContext context,
    FolderDetailController controller,
    Folder folder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteFolderDialog(folderTitle: folder.title),
    );
    if (confirmed != true) return;
    try {
      await controller.deleteFolder();
      if (context.mounted) _back(context);
    } catch (error) {
      if (context.mounted) _showMessage(context, 'Не удалось удалить: $error');
    }
  }

  Future<void> _addLessons(
    BuildContext context,
    WidgetRef ref,
    FolderDetailController controller,
    Folder folder,
  ) async {
    // Candidates are unfiled lessons minus the ones already added.
    final root = ref.read(libraryControllerProvider).value ?? LibraryRoot.empty;
    final present = {for (final lesson in folder.lessons) lesson.id};
    final candidates = [
      for (final lesson in root.lessons)
        if (!present.contains(lesson.id)) lesson,
    ];

    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddLessonsToFolderSheet(candidates: candidates),
    );
    if (selected == null || selected.isEmpty) return;
    try {
      await controller.addLessons(selected);
    } catch (error) {
      if (context.mounted) _showMessage(context, 'Не удалось добавить: $error');
    }
  }

  Future<void> _removeLesson(
    BuildContext context,
    FolderDetailController controller,
    String lessonId,
  ) async {
    try {
      await controller.removeLesson(lessonId);
    } catch (error) {
      if (context.mounted) _showMessage(context, 'Не удалось убрать: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(folderDetailControllerProvider(folderId));
    final controller = ref.read(
      folderDetailControllerProvider(folderId).notifier,
    );
    final role = ref.watch(
      authControllerProvider.select((auth) => auth.user?.role),
    );

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: switch (async) {
          AsyncError(:final error) => _FolderError(
            message: '$error',
            onBack: () => _back(context),
          ),
          AsyncData(:final value) => _FolderContent(
            folder: value,
            canModify: canModifyFolder(role, value),
            onBack: () => _back(context),
            onOpenLesson: (lesson) => _openLesson(context, lesson),
            onRename: () => _rename(context, controller, value),
            onDelete: () => _delete(context, controller, value),
            onAddLessons: () => _addLessons(context, ref, controller, value),
            onRemoveLesson: (id) => _removeLesson(context, controller, id),
            onRefresh: controller.refresh,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Message shown when a folder fails to load.
class _FolderError extends StatelessWidget {
  const _FolderError({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        _FolderTopBar(title: 'Папка', onBack: onBack),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: colors.text2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Open folder body: header, the add-lessons button and the lesson list.
class _FolderContent extends StatelessWidget {
  const _FolderContent({
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
        _FolderTopBar(
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
                          label: 'Добавить уроки',
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
                          ? 'В папке пока нет уроков. Добавьте их кнопкой выше.'
                          : 'В папке пока нет уроков.',
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

/// Folder screen header: back, title and the author action menu.
class _FolderTopBar extends StatelessWidget {
  const _FolderTopBar({
    required this.title,
    required this.onBack,
    this.onRename,
    this.onDelete,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasMenu = onRename != null || onDelete != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.chevron_left,
            semanticLabel: 'Назад',
            shape: AppIconButtonShape.square,
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              title,
              style: AppText.h2.copyWith(color: colors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMenu)
            PopupMenuButton<String>(
              icon: AppIcon(AppIcons.moreVertical, color: colors.text2),
              onSelected: (value) {
                if (value == 'rename') onRename?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onRename != null)
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Переименовать'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить папку'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
