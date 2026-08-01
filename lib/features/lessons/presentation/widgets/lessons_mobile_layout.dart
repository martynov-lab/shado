import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/lesson.dart';
import 'account_menu.dart';
import 'empty_lessons_view.dart';
import 'lessons_filter_bar.dart';
import 'lessons_header.dart';
import 'lessons_list_view.dart';
import 'lessons_no_results.dart';
import 'lesson_search_field.dart';

/// Раскладка списка уроков на телефоне: шапка, поиск, фильтры и список строк.
class LessonsMobileLayout extends StatelessWidget {
  const LessonsMobileLayout({
    super.key,
    required this.lessons,
    required this.emptyLibrary,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<Lesson> lessons;

  /// В библиотеке нет уроков вовсе — вместо поиска и фильтров показываем
  /// заглушку.
  final bool emptyLibrary;

  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s5,
              AppSpacing.s4,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonsHeader(
                  count: lessons.length,
                  trailing: const AccountMenu(),
                ),
                if (!emptyLibrary) ...[
                  const SizedBox(height: AppSpacing.s4),
                  const LessonSearchField(),
                  const SizedBox(height: AppSpacing.s3),
                  const LessonsFilterBar(),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Expanded(
            child: emptyLibrary
                ? const EmptyLessonsView()
                : lessons.isEmpty
                ? const LessonsNoResults()
                : LessonsListView(
                    lessons: lessons,
                    onOpen: onOpen,
                    onDelete: onDelete,
                    onRefresh: onRefresh,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      0,
                      AppSpacing.s4,
                      AppSpacing.s4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
