import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/lesson.dart';
import 'account_menu.dart';
import 'empty_lessons_view.dart';
import 'lessons_filter_bar.dart';
import 'lessons_grid_view.dart';
import 'lessons_header.dart';
import 'lessons_no_results.dart';
import 'lesson_search_field.dart';

/// Раскладка списка уроков на планшете: шапка, поиск, фильтры и сетка карточек.
class LessonsTabletLayout extends StatelessWidget {
  const LessonsTabletLayout({
    super.key,
    required this.lessons,
    required this.emptyLibrary,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<Lesson> lessons;
  final bool emptyLibrary;
  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonsHeader(count: lessons.length, trailing: const AccountMenu()),
            if (!emptyLibrary) ...[
              const SizedBox(height: AppSpacing.s3),
              const LessonSearchField(),
              const SizedBox(height: AppSpacing.s3),
              const LessonsFilterBar(),
            ],
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: emptyLibrary
                  ? const EmptyLessonsView()
                  : lessons.isEmpty
                  ? const LessonsNoResults()
                  : LessonsGridView(
                      lessons: lessons,
                      onOpen: onOpen,
                      onDelete: onDelete,
                      onRefresh: onRefresh,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
