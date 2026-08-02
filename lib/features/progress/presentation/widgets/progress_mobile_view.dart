import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'achievements_wrap.dart';
import 'activity_heatmap.dart';
import 'level_progress_bar.dart';
import 'minutes_bar_chart.dart';
import 'progress_card.dart';
import 'progress_header.dart';
import 'progress_sample.dart';
import 'progress_stats_row.dart';
import 'streak_hero_card.dart';

/// Прогресс на телефоне: одна колонка с прокруткой — серия, статистика,
/// график минут, тепловая карта, уровень и достижения.
class ProgressMobileView extends StatelessWidget {
  const ProgressMobileView({super.key});

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
          const StreakHeroCard(
            days: ProgressSample.streakDays,
            hint: ProgressSample.streakHint,
          ),
          const SizedBox(height: AppSpacing.s4),
          const ProgressStatsRow(stats: ProgressSample.weekStats),
          const SizedBox(height: AppSpacing.s4),
          const ProgressCard(
            title: 'Минуты по дням',
            caption: 'эта неделя',
            child: MinutesBarChart(
              values: ProgressSample.weekMinutes,
              labels: ProgressSample.weekDays,
              todayIndex: ProgressSample.todayIndex,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          ProgressCard(
            title: 'Активность',
            caption: '10 недель',
            child: ActivityHeatmap(cells: ProgressSample.activity),
          ),
          const SizedBox(height: AppSpacing.s4),
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
