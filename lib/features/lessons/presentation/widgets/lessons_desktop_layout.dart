import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import 'empty_lessons_view.dart';
import 'lessons_filter_panel.dart';
import 'lessons_header.dart';
import 'lessons_list_view.dart';
import 'lessons_no_results.dart';
import 'lesson_search_field.dart';

/// Desktop lesson list: a row column and a filter panel on the right.
class LessonsDesktopLayout extends StatelessWidget {
  const LessonsDesktopLayout({
    super.key,
    required this.lessons,
    required this.emptyLibrary,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
    this.onCreateFolder,
  });

  final List<Lesson> lessons;
  final bool emptyLibrary;
  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;

  final List<Folder> folders;
  final void Function(Folder)? onOpenFolder;
  final VoidCallback? onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LessonsHeader(
                    count: lessons.length,
                    trailing: emptyLibrary
                        ? null
                        : const SizedBox(
                            width: 280,
                            child: LessonSearchField(),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Expanded(
                    child: emptyLibrary
                        ? const EmptyLessonsView()
                        : lessons.isEmpty && folders.isEmpty
                        ? const LessonsNoResults()
                        : LessonsListView(
                            lessons: lessons,
                            folders: folders,
                            onOpen: onOpen,
                            onDelete: onDelete,
                            onRefresh: onRefresh,
                            onOpenFolder: onOpenFolder,
                            onCreateFolder: onCreateFolder,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!emptyLibrary) const LessonsFilterPanel(),
      ],
    );
  }
}
