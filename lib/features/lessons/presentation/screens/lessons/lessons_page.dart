import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../widgets/lesson_search_field.dart';
import '../../widgets/lessons_desktop_layout.dart';
import '../../widgets/lessons_error_view.dart';
import '../../widgets/lessons_filter_bar.dart';
import '../../widgets/lessons_filter_options.dart';
import '../../widgets/lessons_filter_panel.dart';
import '../../widgets/lessons_mobile_layout.dart';
import '../../widgets/lessons_tablet_layout.dart';
import 'lessons_wm.dart';

/// Lessons section: root folders and lessons with catalog-wide search.
class LessonsPage extends ElementaryWidget<LessonsWidgetModel> {
  const LessonsPage({super.key}) : super(lessonsWidgetModelFactory);

  static const String routePath = '/lessons';

  @override
  Widget build(LessonsWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.content,
        wm.filter,
        wm.groups,
        wm.topics,
        wm.accents,
        wm.canAuthor,
      ]),
      builder: (_, _) {
        final filter = wm.filter.value;
        final searchField = LessonSearchField(onChanged: wm.setQuery);
        final filterBar = LessonsFilterBar(
          filter: filter,
          groups: wm.groups.value,
          onOpenGroup: (group) => unawaited(wm.openFilterGroup(group)),
          onClear: wm.clearFilters,
        );
        final filterPanel = LessonsFilterPanel(
          activeCount: filter.activeCount,
          onClear: wm.clearFilters,
          options: LessonsFilterOptions(
            groups: wm.groups.value,
            filter: filter,
            topics: wm.topics.value,
            accents: wm.accents.value,
            onChanged: wm.setFilter,
          ),
        );
        final onCreateFolder = wm.canAuthor.value
            ? () => unawaited(wm.createFolder())
            : null;

        return switch (wm.content.value) {
          AsyncFailed(:final error) => LessonsErrorView(
            message: '$error',
            onRetryPressed: () => unawaited(wm.retry()),
          ),
          AsyncReady(value: final content) => AppAdaptiveLayout(
            mobile: (_) => LessonsMobileLayout(
              items: content.items,
              folders: content.folders,
              emptyLibrary: content.isLibraryEmpty,
              searchField: searchField,
              filters: filterBar,
              onResetFilters: wm.clearFilters,
              onOpen: wm.openLesson,
              onDelete: (lesson) => unawaited(wm.deleteLesson(lesson)),
              onToggleDownload: (lesson) =>
                  unawaited(wm.toggleDownload(lesson)),
              onRefresh: wm.refresh,
              onOpenFolder: wm.openFolder,
              onCreateFolder: onCreateFolder,
            ),
            tablet: (_) => LessonsTabletLayout(
              items: content.items,
              folders: content.folders,
              emptyLibrary: content.isLibraryEmpty,
              searchField: searchField,
              filters: filterBar,
              onResetFilters: wm.clearFilters,
              onOpen: wm.openLesson,
              onDelete: (lesson) => unawaited(wm.deleteLesson(lesson)),
              onToggleDownload: (lesson) =>
                  unawaited(wm.toggleDownload(lesson)),
              onRefresh: wm.refresh,
              onOpenFolder: wm.openFolder,
              onCreateFolder: onCreateFolder,
            ),
            desktop: (_) => LessonsDesktopLayout(
              items: content.items,
              folders: content.folders,
              emptyLibrary: content.isLibraryEmpty,
              searchField: searchField,
              filters: filterPanel,
              onResetFilters: wm.clearFilters,
              onOpen: wm.openLesson,
              onDelete: (lesson) => unawaited(wm.deleteLesson(lesson)),
              onToggleDownload: (lesson) =>
                  unawaited(wm.toggleDownload(lesson)),
              onRefresh: wm.refresh,
              onOpenFolder: wm.openFolder,
              onCreateFolder: onCreateFolder,
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }
}
