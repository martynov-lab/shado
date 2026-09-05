import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

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
                const _Cover(),
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

/// Square lesson cover: a gradient with a progress bar at the bottom.
class _Cover extends StatelessWidget {
  const _Cover();

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final onGrad = context.colors.primaryOn;

    return ClipRRect(
      borderRadius: AppRadii.rSm,
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppBrand.signGradient),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  SizedBox(
                    width: _size * 0.6,
                    child: ColoredBox(color: onGrad),
                  ),
                  Expanded(
                    child: ColoredBox(color: onGrad.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
