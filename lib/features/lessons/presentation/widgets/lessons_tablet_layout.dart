import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import '../screens/lessons/lesson_list_item.dart';
import 'account_menu.dart';
import 'empty_lessons_view.dart';
import 'folders_section_header.dart';
import 'lessons_grid_view.dart';
import 'lessons_header.dart';
import 'lessons_no_results.dart';

/// Tablet lesson list: header, search, filters and a card grid.
class LessonsTabletLayout extends StatelessWidget {
  const LessonsTabletLayout({
    super.key,
    required this.items,
    required this.emptyLibrary,
    required this.searchField,
    required this.filters,
    required this.onResetFilters,
    required this.onOpen,
    required this.onDelete,
    required this.onToggleDownload,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
    this.onCreateFolder,
  });

  final List<LessonListItem> items;
  final bool emptyLibrary;
  final ValueChanged<Lesson> onOpen;
  final ValueChanged<Lesson> onDelete;

  /// Downloads the lesson for offline study or removes the download.
  final ValueChanged<Lesson> onToggleDownload;
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonsHeader(count: items.length, trailing: const AccountMenu()),
            if (!emptyLibrary) ...[
              const SizedBox(height: AppSpacing.s3),
              searchField,
              const SizedBox(height: AppSpacing.s3),
              filters,
            ],
            const SizedBox(height: AppSpacing.s4),
            if (!emptyLibrary && onCreateFolder != null)
              FoldersSectionHeader(onCreate: onCreateFolder),
            Expanded(
              child: emptyLibrary
                  ? const EmptyLessonsView()
                  : items.isEmpty && folders.isEmpty
                  ? LessonsNoResults(onResetFilters: onResetFilters)
                  : LessonsGridView(
                      items: items,
                      folders: folders,
                      onOpen: onOpen,
                      onDelete: onDelete,
                      onToggleDownload: onToggleDownload,
                      onRefresh: onRefresh,
                      onOpenFolder: onOpenFolder,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
