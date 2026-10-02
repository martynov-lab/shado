import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../screens/home_lesson_tile.dart';
import 'continue_hero_play_button.dart';
import 'continue_hero_wave.dart';

/// Continue card with the latest lesson, its progress and a play button.
class ContinueHeroCard extends StatelessWidget {
  const ContinueHeroCard({
    super.key,
    required this.lesson,
    required this.progress,
    required this.onOpen,
  });

  /// The latest lesson; `null` when there is none yet.
  final HomeLessonTile? lesson;

  /// How much of the lesson is done, `0..1`.
  final double progress;

  /// Opens the lesson or the lesson list.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final onGrad = context.colors.primaryOn;
    final tile = lesson;
    final title = tile?.title ?? 'Start your first lesson';
    final subtitle = tile?.subtitle ?? 'Pick a lesson from the catalog';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        gradient: AppBrand.signGradient,
        borderRadius: AppRadii.rXl,
        boxShadow: context.shadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue'.toUpperCase(),
            style: AppText.caption.copyWith(
              color: onGrad.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            title,
            style: AppText.h2.copyWith(color: onGrad),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            subtitle,
            style: AppText.label.copyWith(
              color: onGrad.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s4),
          const ContinueHeroWave(),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadii.rPill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: onGrad.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(onGrad),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              ContinueHeroPlayButton(onTap: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}
