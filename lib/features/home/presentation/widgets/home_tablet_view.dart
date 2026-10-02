import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/home_overview.dart';
import 'continue_hero_card.dart';
import 'home_card.dart';
import 'home_goal_ring.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_section_header.dart';
import 'home_stats_row.dart';

/// Home on tablet: continue next to the weekly goal, stats and lessons.
class HomeTabletView extends StatelessWidget {
  const HomeTabletView({
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
    final preview = lessons.take(2).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          HomeGreeting(
            name: overview.greetingName,
            streakDays: overview.streakDays,
            showStreak: true,
          ),
          const SizedBox(height: AppSpacing.s5),
          // Card heights are not aligned — the goal text may wrap.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ContinueHeroCard(
                  lesson: hero,
                  progress: heroProgress,
                  onOpen: hero == null
                      ? onOpenLessons
                      : () => onOpenLesson(hero.id),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                flex: 2,
                child: HomeCard(
                  title: 'Weekly goal',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeGoalRing(
                        ratio: overview.goalRatio,
                        value: overview.goalValue,
                        remaining: overview.goalRemaining,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      AppButton(
                        label: 'Break down a new lesson',
                        variant: AppButtonVariant.secondary,
                        expand: true,
                        onPressed: onOpenLessons,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          HomeStatsRow(stats: overview.stats),
          const SizedBox(height: AppSpacing.s5),
          HomeSectionHeader(
            title: 'My lessons',
            actionLabel: 'All ${overview.lessonsCount}',
            onAction: onOpenLessons,
          ),
          const SizedBox(height: AppSpacing.s2),
          for (var i = 0; i < preview.length; i++)
            HomeLessonRow(
              index: (i + 1).toString().padLeft(2, '0'),
              title: preview[i].title,
              subtitle: preview[i].subtitle,
              time: preview[i].time,
              onTap: () => onOpenLesson(preview[i].id),
            ),
        ],
      ),
    );
  }
}
