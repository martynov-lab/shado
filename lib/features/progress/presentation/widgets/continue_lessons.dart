import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/controllers/lessons_controller.dart';
import '../../../lessons/presentation/pages/lesson_page.dart';

/// Continue block with recent lessons; hidden when there are none.
class ContinueLessons extends ConsumerWidget {
  const ContinueLessons({super.key, required this.lessonIds});

  final List<String> lessonIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lessonIds.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final lessons = ref.watch(lessonsControllerProvider).value ?? const <Lesson>[];
    final byId = {for (final lesson in lessons) lesson.id: lesson};
    final recent = [
      for (final id in lessonIds) ?byId[id],
    ];
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Продолжить', style: AppText.title.copyWith(color: colors.text)),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
            itemBuilder: (context, index) => _ContinueCard(lesson: recent[index]),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: () => context.push(LessonPage.routeTo(lesson.id)),
      semanticLabel: lesson.title,
      child: SizedBox(
        width: 180,
        child: Row(
          children: [
            AppIcon(AppIcons.play, size: AppSizes.iconMd, color: colors.primary),
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
