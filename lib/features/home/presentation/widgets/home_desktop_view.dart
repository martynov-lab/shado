import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/home_lesson_tile.dart';
import '../controllers/home_view_model.dart';
import 'continue_hero_card.dart';
import 'home_card.dart';
import 'home_goal_ring.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_minutes_mini.dart';
import 'home_section_header.dart';
import 'home_stat.dart';
import 'home_week_dots.dart';

/// Главная на десктопе: основная колонка с дашбордом и боковая панель справа
/// (неделя, цель, минуты). Левое меню приложения рисует каркас [MainShell].
class HomeDesktopView extends StatelessWidget {
  const HomeDesktopView({
    super.key,
    required this.name,
    required this.model,
    required this.lessons,
    required this.lessonsCount,
    required this.onOpenLessons,
    required this.onOpenLesson,
  });

  final String name;
  final HomeViewModel model;
  final List<HomeLessonTile> lessons;
  final int lessonsCount;
  final VoidCallback onOpenLessons;
  final void Function(String lessonId) onOpenLesson;

  static const double _panelWidth = 320;

  @override
  Widget build(BuildContext context) {
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
                HomeGreeting(name: name, showAccount: false),
                const SizedBox(height: AppSpacing.s5),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ContinueHeroCard(
                          lesson: hero,
                          onOpen: hero == null
                              ? onOpenLessons
                              : () => onOpenLesson(hero.id),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      for (var i = 0; i < model.statsCompact.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.s4),
                        Expanded(
                          flex: 2,
                          child: HomeStat(
                            caption: model.statsCompact[i].$1,
                            value: model.statsCompact[i].$2,
                            unit: model.statsCompact[i].$3,
                            delta: model.statsCompact[i].$4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                HomeSectionHeader(
                  title: 'Мои уроки',
                  actionLabel: 'Все $lessonsCount',
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
                  title: 'Эта неделя',
                  child: HomeWeekDots(
                    days: model.weekDays,
                    done: model.weekDone,
                    todayIndex: model.weekTodayIndex,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                HomeCard(
                  title: 'Цель недели',
                  child: HomeGoalRing(
                    ratio: model.goalRatio,
                    value: model.goalValue,
                    remaining: model.goalRemaining,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                HomeCard(
                  title: 'Минуты по дням',
                  caption: 'эта неделя',
                  child: HomeMinutesMini(values: model.weekMinutes),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
