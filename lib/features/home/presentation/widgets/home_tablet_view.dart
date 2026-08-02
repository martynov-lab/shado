import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'continue_hero_card.dart';
import 'home_card.dart';
import 'home_goal_ring.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_sample.dart';
import 'home_section_header.dart';
import 'home_stats_row.dart';

/// Главная на планшете: приветствие с плашкой серии, «Продолжить» рядом с целью
/// недели, ряд статистики и превью «Мои уроки». Левый rail рисует [MainShell].
class HomeTabletView extends StatelessWidget {
  const HomeTabletView({
    super.key,
    required this.name,
    required this.onOpenLessons,
  });

  final String name;
  final VoidCallback onOpenLessons;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          HomeGreeting(name: name, showStreak: true),
          const SizedBox(height: AppSpacing.s5),
          // Высоту карточкам не выравниваем: в узких планшетах текст цели может
          // переноситься, и жёсткая высота дала бы переполнение.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ContinueHeroCard(onPlay: onOpenLessons)),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                flex: 2,
                child: HomeCard(
                  title: 'Цель недели',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeGoalRing(
                        ratio: HomeSample.weekGoalRatio,
                        value: HomeSample.weekGoalValue,
                        remaining: HomeSample.weekGoalRemaining,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      AppButton(
                        label: 'Разобрать новый урок',
                        variant: AppButtonVariant.secondary,
                        expand: true,
                        onPressed: onOpenLessons,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          const HomeStatsRow(stats: HomeSample.stats),
          const SizedBox(height: AppSpacing.s5),
          HomeSectionHeader(
            title: 'Мои уроки',
            actionLabel: HomeSample.lessonsAllLabel,
            onAction: onOpenLessons,
          ),
          const SizedBox(height: AppSpacing.s2),
          for (var i = 0; i < 2; i++)
            HomeLessonRow(
              index: (i + 1).toString().padLeft(2, '0'),
              title: HomeSample.lessons[i].$1,
              subtitle: HomeSample.lessons[i].$2,
              time: HomeSample.lessons[i].$3,
              onTap: onOpenLessons,
            ),
        ],
      ),
    );
  }
}
