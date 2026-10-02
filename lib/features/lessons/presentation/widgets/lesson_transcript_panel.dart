import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';


/// Panel with the current segment text and its translation.
class LessonTranscriptPanel extends StatelessWidget {
  const LessonTranscriptPanel({super.key, required this.text});

  /// Text of what the player shows.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              AppIcon(
                AppIcons.translate,
                size: AppSizes.iconSm,
                color: colors.text3,
              ),
              const SizedBox(width: AppSpacing.s1),
              Text(
                'Translation',
                style: AppText.label.copyWith(color: colors.text3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.text,
            ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.s4),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'The segment translation will appear once the server sends it.',
            style: AppText.caption.copyWith(color: colors.text3),
          ),
        ],
      ),
    );
  }
}
