import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../screens/home_overview.dart';
import 'continue_hero_card.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_section_header.dart';
import 'home_stats_row.dart';

/// Home on phone: a single scrollable column.
class HomeMobileView extends StatelessWidget {
  const HomeMobileView({
    super.key,
    required this.overview,
    required this.heroProgress,
    required this.onOpenLessons,
    required this.onOpenLesson,
  });

  final HomeOverview overview;

  /// Progress of the lesson in the continue card, `0..1`.
  final double heroProgress;
  final VoidCallback onOpenLessons;
  final void Function(String lessonId) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final lessons = overview.lessons;
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
          HomeGreeting(name: overview.greetingName),
          const SizedBox(height: AppSpacing.s5),
          ContinueHeroCard(
            lesson: hero,
            progress: heroProgress,
            onOpen: hero == null ? onOpenLessons : () => onOpenLesson(hero.id),
          ),
          const SizedBox(height: AppSpacing.s5),
          HomeStatsRow(stats: overview.stats, scrollable: true),
          const SizedBox(height: AppSpacing.s6),
          HomeSectionHeader(
            title: 'My lessons',
            actionLabel: 'All',
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
