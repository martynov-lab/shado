import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../controllers/lessons_controller.dart';
import '../controllers/lessons_filter.dart';
import '../controllers/library_controller.dart';
import '../widgets/delete_lesson_dialog.dart';
import '../widgets/folder_editor_dialog.dart';
import '../widgets/lessons_desktop_layout.dart';
import '../widgets/lessons_error_view.dart';
import '../widgets/lessons_mobile_layout.dart';
import '../widgets/lessons_tablet_layout.dart';
import 'folder_page.dart';
import 'lesson_page.dart';

/// Lessons section: root folders and lessons with catalog-wide search.
class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  static const String routePath = '/lessons';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);
    final lessonsController = ref.read(lessonsControllerProvider.notifier);
    final lessons = ref.watch(visibleLessonsProvider);
    final folders = ref.watch(visibleFoldersProvider);
    final canAuthor = ref.watch(
      authControllerProvider.select((auth) => auth.canAuthor),
    );

    // Re-read the root and catch the cache up; search relies on it.
    Future<void> refresh() async {
      await Future.wait([
        libraryController.refresh(),
        lessonsController.refresh(),
      ]);
    }

    return switch (library) {
      AsyncError(:final error) => LessonsErrorView(
        message: '$error',
        onRetryPressed: libraryController.refresh,
      ),
      AsyncData(value: final root) => AppAdaptiveLayout(
        mobile: (context) => LessonsMobileLayout(
          lessons: lessons,
          folders: folders,
          emptyLibrary: root.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) =>
              _confirmDelete(context, lessonsController, lesson),
          onRefresh: refresh,
          onOpenFolder: (folder) => _openFolder(context, folder),
          onCreateFolder: canAuthor ? () => _createFolder(context, ref) : null,
        ),
        tablet: (context) => LessonsTabletLayout(
          lessons: lessons,
          folders: folders,
          emptyLibrary: root.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) =>
              _confirmDelete(context, lessonsController, lesson),
          onRefresh: refresh,
          onOpenFolder: (folder) => _openFolder(context, folder),
          onCreateFolder: canAuthor ? () => _createFolder(context, ref) : null,
        ),
        desktop: (context) => LessonsDesktopLayout(
          lessons: lessons,
          folders: folders,
          emptyLibrary: root.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) =>
              _confirmDelete(context, lessonsController, lesson),
          onRefresh: refresh,
          onOpenFolder: (folder) => _openFolder(context, folder),
          onCreateFolder: canAuthor ? () => _createFolder(context, ref) : null,
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  void _open(BuildContext context, Lesson lesson) =>
      context.push(LessonPage.routeTo(lesson.id));

  void _openFolder(BuildContext context, Folder folder) =>
      context.push(FolderPage.routeTo(folder.id));

  /// Creates a folder and opens it.
  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const FolderEditorDialog(
        title: 'Новая папка',
        confirmLabel: 'Создать',
      ),
    );
    if (title == null) return;
    try {
      final folder = await ref
          .read(libraryControllerProvider.notifier)
          .create(title);
      if (context.mounted) _openFolder(context, folder);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось создать папку: $error')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LessonsController controller,
    Lesson lesson,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteLessonDialog(lessonTitle: lesson.title),
    );
    if (confirmed != true) return;
    await controller.delete(lesson.id);
  }
}
