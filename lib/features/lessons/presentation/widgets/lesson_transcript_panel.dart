import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Panel with the current segment text and its translation.
class LessonTranscriptPanel extends StatelessWidget {
  const LessonTranscriptPanel({
    super.key,
    required this.text,
    required this.translation,
    required this.onToggleTranslation,
    required this.stars,
    required this.onRate,
  });

  /// Text of what the player shows.
  final String text;

  /// `null` while the translation is hidden; a failure carries its message.
  final AsyncState<String>? translation;

  final VoidCallback onToggleTranslation;

  /// How well the shown text is known, `0..5`.
  final int stars;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final translation = this.translation;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SEGMENT TEXT',
                  style: AppText.caption.copyWith(
                    color: colors.text3,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              AppButton(
                label: translation == null ? 'Translation' : 'Hide',
                icon: Icons.translate_rounded,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: onToggleTranslation,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          SelectableText(
            text,
            style: AppText.body.copyWith(
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.text,
            ),
          ),
          const Spacer(),
          if (translation != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: AppSpacing.s3),
            switch (translation) {
              AsyncReady(:final value) => SelectableText(
                value,
                style: AppText.body.copyWith(color: colors.text2),
              ),
              AsyncFailed(:final error) => Text(
                '$error',
                style: AppText.caption.copyWith(color: colors.text3),
              ),
              AsyncPending() => const SizedBox.square(
                dimension: AppSizes.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            },
          ],
          const SizedBox(height: AppSpacing.s3),
          AppStarRating(value: stars, onChanged: onRate),
        ],
      ),
    );
  }
}
