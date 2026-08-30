import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../controllers/folders_controller.dart';
import '../controllers/lessons_controller.dart';
import '../controllers/lessons_filter.dart';
import '../widgets/delete_lesson_dialog.dart';
import '../widgets/folder_editor_dialog.dart';
import '../widgets/lessons_desktop_layout.dart';
import '../widgets/lessons_error_view.dart';
import '../widgets/lessons_mobile_layout.dart';
import '../widgets/lessons_tablet_layout.dart';
import 'folder_page.dart';
import 'lesson_page.dart';

/// Список уроков — раздел «Уроки». Данные и фильтрацию держат провайдеры,
/// раскладку выбирает [AppAdaptiveLayout]. Каркас (Scaffold, фон, навигация) —
/// у [MainShell]. Над уроками, в том же списке, идут папки (§6.2).
class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  static const String routePath = '/lessons';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsControllerProvider);
    final controller = ref.read(lessonsControllerProvider.notifier);
    final filter = ref.watch(lessonsFilterProvider);
    final filtered =
        ref.watch(filteredLessonsProvider).value ?? const <Lesson>[];
    final canAuthor = ref.watch(
      authControllerProvider.select((auth) => auth.canAuthor),
    );

    // Уроки, уже разложенные по папкам, в общем списке не показываем — они
    // живут внутри своих папок.
    final folderedIds =
        ref.watch(folderedLessonIdsProvider).value ?? const <String>{};
    final visibleLessons = folderedIds.isEmpty
        ? filtered
        : [
            for (final lesson in filtered)
              if (!folderedIds.contains(lesson.id)) lesson,
          ];

    // Папки показываем только пока не сужают уроки категориями: у папки нет ни
    // уровня, ни темы, поэтому при активных фильтрах их скрываем, а по поиску —
    // отбираем по названию.
    final foldersAll =
        ref.watch(foldersControllerProvider).value ?? const <Folder>[];
    final showFolderSection = filter.activeCount == 0;
    final folders = !showFolderSection
        ? const <Folder>[]
        : filter.query.isEmpty
        ? foldersAll
        : [
            for (final folder in foldersAll)
              if (folder.title.toLowerCase().contains(
                filter.query.toLowerCase(),
              ))
                folder,
          ];

    Future<void> refresh() async {
      await Future.wait([
        controller.refresh(),
        ref.read(foldersControllerProvider.notifier).refresh(),
      ]);
    }

    return switch (lessons) {
      AsyncError(:final error) => LessonsErrorView(
        message: '$error',
        onRetryPressed: controller.refresh,
      ),
      AsyncData(value: final items) => AppAdaptiveLayout(
        mobile: (context) => LessonsMobileLayout(
          lessons: visibleLessons,
          folders: folders,
          emptyLibrary: items.isEmpty && foldersAll.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) => _confirmDelete(context, controller, lesson),
          onRefresh: refresh,
          onOpenFolder: (folder) => _openFolder(context, folder),
          onCreateFolder: canAuthor ? () => _createFolder(context, ref) : null,
        ),
        tablet: (context) => LessonsTabletLayout(
          lessons: visibleLessons,
          folders: folders,
          emptyLibrary: items.isEmpty && foldersAll.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) => _confirmDelete(context, controller, lesson),
          onRefresh: refresh,
          onOpenFolder: (folder) => _openFolder(context, folder),
          onCreateFolder: canAuthor ? () => _createFolder(context, ref) : null,
        ),
        desktop: (context) => LessonsDesktopLayout(
          lessons: visibleLessons,
          folders: folders,
          emptyLibrary: items.isEmpty && foldersAll.isEmpty,
          onOpen: (lesson) => _open(context, lesson),
          onDelete: (lesson) => _confirmDelete(context, controller, lesson),
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

  /// Создаёт папку и открывает её — там уже можно добавить в неё уроки.
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
          .read(foldersControllerProvider.notifier)
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
