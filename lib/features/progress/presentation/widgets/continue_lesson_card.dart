import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../lessons/domain/entities/lesson.dart';

/// A recent lesson card in the continue block.
class ContinueLessonCard extends StatelessWidget {
  const ContinueLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      semanticLabel: lesson.title,
      child: SizedBox(
        width: 180,
        child: Row(
          children: [
            AppIcon(
              AppIcons.play,
              size: AppSizes.iconMd,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                lesson.title,
                style: AppText.label.copyWith(color: colors.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
