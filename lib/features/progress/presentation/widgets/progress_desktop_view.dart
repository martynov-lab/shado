import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../screens/progress_overview.dart';
import 'achievements_wrap.dart';
import 'activity_heatmap.dart';
import 'continue_lessons.dart';
import 'level_progress_bar.dart';
import 'minutes_bar_chart.dart';
import 'progress_card.dart';
import 'progress_header.dart';
import 'progress_sample.dart';
import 'progress_stats_row.dart';
import 'streak_hero_card.dart';
import 'weekly_goal_ring.dart';

/// Progress on desktop: a dashboard column and a side panel on the right.
class ProgressDesktopView extends StatelessWidget {
  const ProgressDesktopView({
    super.key,
    required this.overview,
    required this.onOpenLesson,
  });

  final ProgressOverview overview;
  final ValueChanged<Lesson> onOpenLesson;

  static const double _panelWidth = 320;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SafeArea(
            right: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s8),
              children: [
                const ProgressHeader(showAvatar: false),
                const SizedBox(height: AppSpacing.s5),
                ProgressStatsRow(stats: overview.statsWide),
                if (overview.recentLessons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  ContinueLessons(
                    lessons: overview.recentLessons,
                    onOpenLesson: onOpenLesson,
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                ProgressCard(
                  title: 'Minutes per day',
                  caption: 'this week',
                  child: MinutesBarChart(
                    values: overview.weekBars,
                    labels: overview.weekLabels,
                    todayIndex: overview.weekTodayIndex,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                ProgressCard(
                  title: 'Activity',
                  caption: 'last 10 weeks',
                  child: ActivityHeatmap(cells: overview.heatmapCells),
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
              left: BorderSide(
                color: colors.border,
                width: AppSizes.borderThin,
              ),
            ),
          ),
          child: SafeArea(
            left: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s6),
              children: [
                StreakHeroCard(
                  days: overview.streakDays,
                  hint: overview.streakHintShort,
                ),
                const SizedBox(height: AppSpacing.s4),
                ProgressCard(
                  title: 'Weekly goal',
                  child: WeeklyGoalRing(
                    ratio: overview.goalRatio,
                    value: overview.goalValue,
                    remaining: overview.goalRemaining,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                // Design placeholders: there is no server data yet.
                const ProgressCard(
                  title: 'Level',
                  child: LevelProgressBar(
                    fromLevel: ProgressSample.levelFrom,
                    toLevel: ProgressSample.levelTo,
                    ratio: ProgressSample.levelRatio,
                    hint: ProgressSample.levelHintShort,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                ProgressCard(
                  title: 'Achievements',
                  child: AchievementsWrap(
                    items: ProgressSample.achievements.sublist(0, 3),
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
