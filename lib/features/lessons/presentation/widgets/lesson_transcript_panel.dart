import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/lesson_controller.dart';

/// Panel with the current segment text and its translation.
class LessonTranscriptPanel extends ConsumerWidget {
  const LessonTranscriptPanel({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(lessonControllerProvider(lessonId)).value;
    if (state == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ТЕКСТ СЕГМЕНТА',
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
                'Перевод',
                style: AppText.label.copyWith(color: colors.text3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            state.playerText,
            style: AppText.body.copyWith(
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Перевод сегмента появится, когда его пришлёт сервер.',
            style: AppText.caption.copyWith(color: colors.text3),
          ),
        ],
      ),
    );
  }
}
