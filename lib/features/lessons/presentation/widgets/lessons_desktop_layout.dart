import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../screens/lessons/lesson_list_item.dart';
import 'empty_lessons_view.dart';
import 'lessons_header.dart';
import 'lessons_list_view.dart';
import 'lessons_no_results.dart';

/// Desktop lesson list: a row column and a filter panel on the right.
class LessonsDesktopLayout extends StatelessWidget {
  const LessonsDesktopLayout({
    super.key,
    required this.items,
    required this.emptyLibrary,
    required this.searchField,
    required this.filters,
    required this.onResetFilters,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
    this.onCreateFolder,
  });

  final List<LessonListItem> items;
  final bool emptyLibrary;
  final ValueChanged<Lesson> onOpen;
  final ValueChanged<Lesson> onDelete;
  final Future<void> Function() onRefresh;
  final Widget searchField;

  /// The filter chips on narrow screens, the filter panel on desktop.
  final Widget filters;

  final VoidCallback onResetFilters;

  final List<Folder> folders;
  final ValueChanged<Folder>? onOpenFolder;
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
                    count: items.length,
                    trailing: emptyLibrary
                        ? null
                        : SizedBox(
                            width: 280,
                            child: searchField,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Expanded(
                    child: emptyLibrary
                        ? const EmptyLessonsView()
                        : items.isEmpty && folders.isEmpty
                        ? LessonsNoResults(onResetFilters: onResetFilters)
                        : LessonsListView(
                            items: items,
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
        if (!emptyLibrary) filters,
      ],
    );
  }
}
