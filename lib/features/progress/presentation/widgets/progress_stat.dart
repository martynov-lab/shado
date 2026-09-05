import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Stat tile: a label, a large number and a delta below it.
class ProgressStat extends StatelessWidget {
  const ProgressStat({
    super.key,
    required this.caption,
    required this.value,
    required this.delta,
    this.unit,
  });

  final String caption;
  final String value;

  /// Unit next to the number, e.g. minutes.
  final String? unit;

  /// Short caption below.
  final String delta;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: colors.border, width: AppSizes.borderThin),
        boxShadow: context.shadows.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption.toUpperCase(),
            style: AppText.caption.copyWith(
              color: colors.text3,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text.rich(
            TextSpan(
              text: value,
              style: AppText.h2.copyWith(color: colors.text),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppText.caption.copyWith(color: colors.text3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            delta,
            style: AppText.caption.copyWith(
              color: colors.success,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
