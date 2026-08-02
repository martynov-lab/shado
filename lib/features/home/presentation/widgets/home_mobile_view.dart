import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'continue_hero_card.dart';
import 'home_greeting.dart';
import 'home_lesson_row.dart';
import 'home_sample.dart';
import 'home_section_header.dart';
import 'home_stats_row.dart';

/// Главная на телефоне: одна колонка с прокруткой — приветствие, карточка
/// «Продолжить», лента статистики и превью «Мои уроки».
class HomeMobileView extends StatelessWidget {
  const HomeMobileView({
    super.key,
    required this.name,
    required this.onOpenLessons,
  });

  final String name;
  final VoidCallback onOpenLessons;

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
          HomeGreeting(name: name),
          const SizedBox(height: AppSpacing.s5),
          ContinueHeroCard(onPlay: onOpenLessons),
          const SizedBox(height: AppSpacing.s5),
          const HomeStatsRow(stats: HomeSample.stats, scrollable: true),
          const SizedBox(height: AppSpacing.s6),
          HomeSectionHeader(
            title: 'Мои уроки',
            actionLabel: 'Все',
            onAction: onOpenLessons,
          ),
          const SizedBox(height: AppSpacing.s2),
          for (final (title, subtitle, time) in HomeSample.lessons)
            HomeLessonRow(
              title: title,
              subtitle: subtitle,
              time: time,
              onTap: onOpenLessons,
            ),
        ],
      ),
    );
  }
}
