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
import 'weekly_goal_ring.dart';

/// Прогресс на десктопе: основная колонка с дашбордом и боковая панель справа.
/// Левое меню приложения рисует каркас [MainShell], поэтому здесь только эти
/// две области.
class ProgressDesktopView extends StatelessWidget {
  const ProgressDesktopView({super.key, required this.model});

  final ProgressViewModel model;

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
                ProgressStatsRow(stats: model.statsWide),
                if (model.recentLessonIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  ContinueLessons(lessonIds: model.recentLessonIds),
                ],
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
                  caption: 'последние 10 недель',
                  child: ActivityHeatmap(cells: model.heatmapCells),
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
                StreakHeroCard(
                  days: model.streakDays,
                  hint: model.streakHintShort,
                ),
                const SizedBox(height: AppSpacing.s4),
                ProgressCard(
                  title: 'Цель недели',
                  child: WeeklyGoalRing(
                    ratio: model.goalRatio,
                    value: model.goalValue,
                    remaining: model.goalRemaining,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                // Заглушки из макета: серверных данных пока нет.
                const ProgressCard(
                  title: 'Уровень',
                  child: LevelProgressBar(
                    fromLevel: ProgressSample.levelFrom,
                    toLevel: ProgressSample.levelTo,
                    ratio: ProgressSample.levelRatio,
                    hint: ProgressSample.levelHintShort,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                ProgressCard(
                  title: 'Достижения',
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
