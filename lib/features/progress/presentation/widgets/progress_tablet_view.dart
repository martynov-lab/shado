import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../screens/progress_overview.dart';
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

/// Progress on tablet: streak and weekly goal in two columns, a stats row,
/// the minutes chart beside the heatmap and a full-width level bar.
class ProgressTabletView extends StatelessWidget {
  const ProgressTabletView({
    super.key,
    required this.overview,
    required this.onOpenLesson,
  });

  final ProgressOverview overview;
  final ValueChanged<Lesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          const ProgressHeader(),
          const SizedBox(height: AppSpacing.s5),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: StreakHeroCard(
                    days: overview.streakDays,
                    hint: overview.streakHintShort,
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  flex: 2,
                  child: ProgressCard(
                    title: 'Weekly goal',
                    child: WeeklyGoalRing(
                      ratio: overview.goalRatio,
                      value: overview.goalValue,
                      remaining: overview.goalRemaining,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (overview.recentLessons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            ContinueLessons(
              lessons: overview.recentLessons,
              onOpenLesson: onOpenLesson,
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          ProgressStatsRow(stats: overview.stats),
          const SizedBox(height: AppSpacing.s4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ProgressCard(
                    title: 'Minutes per day',
                    caption: 'week',
                    child: MinutesBarChart(
                      values: overview.weekBars,
                      labels: overview.weekLabels,
                      todayIndex: overview.weekTodayIndex,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: ProgressCard(
                    title: 'Activity',
                    caption: '10 weeks',
                    child: ActivityHeatmap(cells: overview.heatmapCells),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          // Placeholder: there is no server data about the level yet.
          const ProgressCard(
            title: 'Your level',
            child: LevelProgressBar(
              fromLevel: ProgressSample.levelFrom,
              toLevel: ProgressSample.levelTo,
              ratio: ProgressSample.levelRatio,
              hint: ProgressSample.levelHint,
            ),
          ),
        ],
      ),
    );
  }
}
