import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'home_lesson_cover.dart';

/// Lesson preview row: index, cover, title and duration.
class HomeLessonRow extends StatelessWidget {
  const HomeLessonRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
    this.index,
  });

  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;

  /// Ordinal number on the left.
  final String? index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                if (index != null) ...[
                  SizedBox(
                    width: 20,
                    child: Text(
                      index!,
                      textAlign: TextAlign.center,
                      style: AppText.monoTime.copyWith(color: colors.text3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                ],
                const HomeLessonCover(),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppText.label.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        subtitle,
                        style: AppText.caption.copyWith(color: colors.text3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  time,
                  style: AppText.monoTime.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
