import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/lesson_controller.dart';
import '../controllers/lesson_permissions.dart';

/// Lesson screen header: back, the title with a subtitle and the edit button.
class LessonHeader extends ConsumerWidget {
  const LessonHeader({
    super.key,
    required this.lessonId,
    required this.onBack,
    required this.onEdit,
  });

  final String lessonId;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(lessonControllerProvider(lessonId)).value;
    final lesson = state?.lesson;
    final role = ref.watch(
      authControllerProvider.select((auth) => auth.user?.role),
    );
    // The edit button follows permissions; the server still decides.
    final canEdit = lesson != null && canModifyLesson(role, lesson);

    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_rounded,
          semanticLabel: 'Назад',
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lesson?.title ?? 'Урок',
                style: AppText.title.copyWith(color: colors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (state != null)
                Text(
                  _subtitle(state),
                  style: AppText.caption.copyWith(color: colors.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (canEdit) ...[
          const SizedBox(width: AppSpacing.s3),
          AppIconButton(
            icon: Icons.edit_outlined,
            semanticLabel: 'Править разбивку',
            onPressed: onEdit,
          ),
        ],
      ],
    );
  }

  String _subtitle(LessonState state) {
    final lesson = state.lesson;
    return [
      if (lesson.topic != null && lesson.topic!.name.isNotEmpty)
        lesson.topic!.name,
      'сегмент ${state.currentIndex + 1} из ${lesson.segmentCount}',
      if (lesson.level != null) lesson.level!.wire.toUpperCase(),
    ].join(' · ');
  }
}
