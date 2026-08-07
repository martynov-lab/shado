import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/progress_view_model.dart';
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

/// Прогресс на планшете: серия и цель недели в два столбца, ряд статистики,
/// график минут рядом с тепловой картой и полоса уровня во всю ширину.
class ProgressTabletView extends StatelessWidget {
  const ProgressTabletView({super.key, required this.model});

  final ProgressViewModel model;

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
                    days: model.streakDays,
                    hint: model.streakHintShort,
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  flex: 2,
                  child: ProgressCard(
                    title: 'Цель недели',
                    child: WeeklyGoalRing(
                      ratio: model.goalRatio,
                      value: model.goalValue,
                      remaining: model.goalRemaining,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (model.recentLessonIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            ContinueLessons(lessonIds: model.recentLessonIds),
          ],
          const SizedBox(height: AppSpacing.s4),
          ProgressStatsRow(stats: model.stats),
          const SizedBox(height: AppSpacing.s4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ProgressCard(
                    title: 'Минуты по дням',
                    caption: 'неделя',
                    child: MinutesBarChart(
                      values: model.weekBars,
                      labels: model.weekLabels,
                      todayIndex: model.weekTodayIndex,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: ProgressCard(
                    title: 'Активность',
                    caption: '10 недель',
                    child: ActivityHeatmap(cells: model.heatmapCells),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          // Заглушка из макета: серверных данных об уровне пока нет.
          const ProgressCard(
            title: 'Твой уровень',
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
