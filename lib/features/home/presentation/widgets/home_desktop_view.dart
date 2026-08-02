import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'continue_hero_card.dart';
import 'home_card.dart';
import 'home_goal_ring.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_minutes_mini.dart';
import 'home_sample.dart';
import 'home_section_header.dart';
import 'home_stat.dart';
import 'home_week_dots.dart';

/// Главная на десктопе: основная колонка с дашбордом и боковая панель справа
/// (неделя, цель, минуты). Левое меню приложения рисует каркас [MainShell].
class HomeDesktopView extends StatelessWidget {
  const HomeDesktopView({
    super.key,
    required this.name,
    required this.onOpenLessons,
  });

  final String name;
  final VoidCallback onOpenLessons;

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
                HomeGreeting(name: name, showAccount: false),
                const SizedBox(height: AppSpacing.s5),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ContinueHeroCard(onPlay: onOpenLessons),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      for (var i = 0; i < HomeSample.statsCompact.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.s4),
                        Expanded(
                          flex: 2,
                          child: HomeStat(
                            caption: HomeSample.statsCompact[i].$1,
                            value: HomeSample.statsCompact[i].$2,
                            unit: HomeSample.statsCompact[i].$3,
                            delta: HomeSample.statsCompact[i].$4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                HomeSectionHeader(
                  title: 'Мои уроки',
                  actionLabel: HomeSample.lessonsAllLabel,
                  onAction: onOpenLessons,
                ),
                const SizedBox(height: AppSpacing.s2),
                for (var i = 0; i < HomeSample.lessons.length; i++)
                  HomeLessonRow(
                    index: (i + 1).toString().padLeft(2, '0'),
                    title: HomeSample.lessons[i].$1,
                    subtitle: HomeSample.lessons[i].$2,
                    time: HomeSample.lessons[i].$3,
                    onTap: onOpenLessons,
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
              children: const [
                HomeCard(
                  title: 'Эта неделя',
                  child: HomeWeekDots(
                    days: HomeSample.weekDays,
                    done: HomeSample.weekDone,
                    todayIndex: HomeSample.todayIndex,
                  ),
                ),
                SizedBox(height: AppSpacing.s4),
                HomeCard(
                  title: 'Цель недели',
                  child: HomeGoalRing(
                    ratio: HomeSample.weekGoalRatio,
                    value: HomeSample.weekGoalValue,
                    remaining: HomeSample.weekGoalRemaining,
                  ),
                ),
                SizedBox(height: AppSpacing.s4),
                HomeCard(
                  title: 'Минуты по дням',
                  caption: 'эта неделя',
                  child: HomeMinutesMini(values: HomeSample.weekMinutes),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
