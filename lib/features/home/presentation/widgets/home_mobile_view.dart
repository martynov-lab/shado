import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/home_lesson_tile.dart';
import '../controllers/home_view_model.dart';
import 'continue_hero_card.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_section_header.dart';
import 'home_stats_row.dart';

/// Главная на телефоне: одна колонка с прокруткой — приветствие, карточка
/// «Продолжить», лента статистики и превью «Мои уроки».
class HomeMobileView extends StatelessWidget {
  const HomeMobileView({
    super.key,
    required this.name,
    required this.model,
    required this.lessons,
    required this.onOpenLessons,
    required this.onOpenLesson,
  });

  final String name;
  final HomeViewModel model;
  final List<HomeLessonTile> lessons;
  final VoidCallback onOpenLessons;
  final void Function(String lessonId) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final hero = lessons.isEmpty ? null : lessons.first;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s6,
        ),
        children: [
          HomeGreeting(name: name),
          const SizedBox(height: AppSpacing.s5),
          ContinueHeroCard(
            lesson: hero,
            onOpen: hero == null ? onOpenLessons : () => onOpenLesson(hero.id),
          ),
          const SizedBox(height: AppSpacing.s5),
          HomeStatsRow(stats: model.stats, scrollable: true),
          const SizedBox(height: AppSpacing.s6),
          HomeSectionHeader(
            title: 'Мои уроки',
            actionLabel: 'Все',
            onAction: onOpenLessons,
          ),
          const SizedBox(height: AppSpacing.s2),
          for (final lesson in lessons)
            HomeLessonRow(
              title: lesson.title,
              subtitle: lesson.subtitle,
              time: lesson.time,
              onTap: () => onOpenLesson(lesson.id),
            ),
        ],
      ),
    );
  }
}
