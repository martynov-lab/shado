import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/progress_view_model.dart';
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
  const ProgressMobileView({super.key, required this.model});

  final ProgressViewModel model;

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
          StreakHeroCard(days: model.streakDays, hint: model.streakHint),
          if (model.recentLessonIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            ContinueLessons(lessonIds: model.recentLessonIds),
          ],
          const SizedBox(height: AppSpacing.s4),
          ProgressStatsRow(stats: model.stats),
          const SizedBox(height: AppSpacing.s4),
          ProgressCard(
            title: 'Минуты по дням',
            caption: 'эта неделя',
            child: MinutesBarChart(
              values: model.weekBars,
              labels: model.weekLabels,
              todayIndex: model.weekTodayIndex,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          ProgressCard(
            title: 'Активность',
            caption: '10 недель',
            child: ActivityHeatmap(cells: model.heatmapCells),
          ),
          const SizedBox(height: AppSpacing.s4),
          // Placeholder: there is no server data about the level yet.
          const ProgressCard(
            title: 'Твой уровень',
            child: LevelProgressBar(
              fromLevel: ProgressSample.levelFrom,
              toLevel: ProgressSample.levelTo,
              ratio: ProgressSample.levelRatio,
              hint: ProgressSample.levelHint,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const ProgressCard(
            title: 'Достижения',
            child: AchievementsWrap(items: ProgressSample.achievements),
          ),
        ],
      ),
    );
  }
}
