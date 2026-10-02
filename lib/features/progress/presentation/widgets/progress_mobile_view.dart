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

/// Progress on phone: a single scrollable column.
class ProgressMobileView extends StatelessWidget {
  const ProgressMobileView({
    super.key,
    required this.overview,
    required this.onOpenLesson,
  });

  final ProgressOverview overview;
  final ValueChanged<Lesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
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
          const ProgressHeader(),
          const SizedBox(height: AppSpacing.s5),
          StreakHeroCard(days: overview.streakDays, hint: overview.streakHint),
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
            caption: '10 weeks',
            child: ActivityHeatmap(cells: overview.heatmapCells),
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
          const SizedBox(height: AppSpacing.s4),
          const ProgressCard(
            title: 'Achievements',
            child: AchievementsWrap(items: ProgressSample.achievements),
          ),
        ],
      ),
    );
  }
}
