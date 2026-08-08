import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/home_lesson_tile.dart';
import '../controllers/home_view_model.dart';
import 'continue_hero_card.dart';
import 'home_card.dart';
import 'home_goal_ring.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_section_header.dart';
import 'home_stats_row.dart';

/// Главная на планшете: приветствие с плашкой серии, «Продолжить» рядом с целью
/// недели, ряд статистики и превью «Мои уроки». Левый rail рисует [MainShell].
class HomeTabletView extends StatelessWidget {
  const HomeTabletView({
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

  @override
  Widget build(BuildContext context) {
    final hero = lessons.isEmpty ? null : lessons.first;
    final preview = lessons.take(2).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          HomeGreeting(name: name, streakDays: model.streakDays, showStreak: true),
          const SizedBox(height: AppSpacing.s5),
          // Высоту карточкам не выравниваем: в узких планшетах текст цели может
          // переноситься, и жёсткая высота дала бы переполнение.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                flex: 2,
                child: HomeCard(
                  title: 'Цель недели',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeGoalRing(
                        ratio: model.goalRatio,
                        value: model.goalValue,
                        remaining: model.goalRemaining,
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
          HomeStatsRow(stats: model.stats),
          const SizedBox(height: AppSpacing.s5),
          HomeSectionHeader(
            title: 'Мои уроки',
            actionLabel: 'Все $lessonsCount',
            onAction: onOpenLessons,
          ),
          const SizedBox(height: AppSpacing.s2),
          for (var i = 0; i < preview.length; i++)
            HomeLessonRow(
              index: (i + 1).toString().padLeft(2, '0'),
              title: preview[i].title,
              subtitle: preview[i].subtitle,
              time: preview[i].time,
              onTap: () => onOpenLesson(preview[i].id),
            ),
        ],
      ),
    );
  }
}
