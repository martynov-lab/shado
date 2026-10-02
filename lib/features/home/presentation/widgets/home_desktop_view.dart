import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../screens/home_overview.dart';
import 'continue_hero_card.dart';
import 'home_card.dart';
import 'home_goal_ring.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_minutes_mini.dart';
import 'home_section_header.dart';
import 'home_stat.dart';
import 'home_week_dots.dart';

/// Home on desktop: a dashboard column and a side panel on the right.
class HomeDesktopView extends StatelessWidget {
  const HomeDesktopView({
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

  static const double _panelWidth = 320;

  @override
  Widget build(BuildContext context) {
    final lessons = overview.lessons;
    final colors = context.colors;
    final hero = lessons.isEmpty ? null : lessons.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SafeArea(
            right: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s8),
              children: [
                HomeGreeting(name: overview.greetingName, showAccount: false),
                const SizedBox(height: AppSpacing.s5),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      for (var i = 0; i < overview.statsCompact.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.s4),
                        Expanded(
                          flex: 2,
                          child: HomeStat(
                            caption: overview.statsCompact[i].$1,
                            value: overview.statsCompact[i].$2,
                            unit: overview.statsCompact[i].$3,
                            delta: overview.statsCompact[i].$4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                HomeSectionHeader(
                  title: 'My lessons',
                  actionLabel: 'All ${overview.lessonsCount}',
                  onAction: onOpenLessons,
                ),
                const SizedBox(height: AppSpacing.s2),
                for (var i = 0; i < lessons.length; i++)
                  HomeLessonRow(
                    index: (i + 1).toString().padLeft(2, '0'),
                    title: lessons[i].title,
                    subtitle: lessons[i].subtitle,
                    time: lessons[i].time,
                    onTap: () => onOpenLesson(lessons[i].id),
                  ),
              ],
            ),
          ),
        ),
        Container(
          width: _panelWidth,
          decoration: BoxDecoration(
            color: colors.surface2,
            border: Border(
              left: BorderSide(color: colors.border, width: AppSizes.borderThin),
            ),
          ),
          child: SafeArea(
            left: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s6),
              children: [
                HomeCard(
                  title: 'This week',
                  child: HomeWeekDots(
                    days: overview.weekDays,
                    done: overview.weekDone,
                    todayIndex: overview.weekTodayIndex,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                HomeCard(
                  title: 'Weekly goal',
                  child: HomeGoalRing(
                    ratio: overview.goalRatio,
                    value: overview.goalValue,
                    remaining: overview.goalRemaining,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                HomeCard(
                  title: 'Minutes per day',
                  caption: 'this week',
                  child: HomeMinutesMini(
                    values: overview.weekMinutes,
                    labels: overview.weekDays,
                    todayIndex: overview.weekTodayIndex,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
