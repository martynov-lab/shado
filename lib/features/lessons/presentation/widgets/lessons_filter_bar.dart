import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/lessons_filter.dart';
import 'lessons_filter_options.dart';

/// Ряд фильтров списка для телефона и планшета: чип на каждую группу открывает
/// лист с флажками, а «Сбросить» очищает выбранное. Всегда в одну строку —
/// при нехватке места прокручивается вбок.
class LessonsFilterBar extends ConsumerWidget {
  const LessonsFilterBar({super.key});

  Future<void> _open(BuildContext context, LessonFilterGroup group) {
    return showAppBottomSheet<void>(
      context: context,
      title: group.title,
      builder: (context) =>
          SingleChildScrollView(child: LessonsFilterOptions(only: group)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(lessonsFilterProvider);
    final notifier = ref.read(lessonsFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterTrigger(
            label: LessonFilterGroup.topic.title,
            count: filter.topicIds.length,
            onTap: () => _open(context, LessonFilterGroup.topic),
          ),
          const SizedBox(width: AppSpacing.s2),
          _FilterTrigger(
            label: LessonFilterGroup.level.title,
            count: filter.levels.length,
            onTap: () => _open(context, LessonFilterGroup.level),
          ),
          const SizedBox(width: AppSpacing.s2),
          _FilterTrigger(
            label: LessonFilterGroup.status.title,
            count: filter.statuses.length,
            onTap: () => _open(context, LessonFilterGroup.status),
          ),
          if (filter.activeCount > 0) ...[
            const SizedBox(width: AppSpacing.s2),
            _ClearButton(onTap: notifier.clearFilters),
          ],
        ],
      ),
    );
  }
}

class _FilterTrigger extends StatelessWidget {
  const _FilterTrigger({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = count > 0;
    final foreground = active ? colors.primary : colors.text2;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppTapTarget(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.rPill,
            child: Container(
              height: AppSizes.controlSm,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                color: active ? colors.primarySoft : colors.surface,
                borderRadius: AppRadii.rPill,
                border: Border.all(
                  color: active ? colors.primary : colors.border,
                  width: AppSizes.borderThin,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppText.label.copyWith(color: foreground)),
                  if (active) ...[
                    const SizedBox(width: AppSpacing.s2),
                    _CountBadge(count),
                  ],
                  const SizedBox(width: AppSpacing.s1),
                  AppIcon(
                    AppIcons.chevronDown,
                    size: AppSizes.iconSm,
                    color: foreground,
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

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        '$count',
        style: AppText.caption.copyWith(color: colors.primaryOn),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      child: AppTapTarget(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.rPill,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Text(
                'Сбросить',
                style: AppText.label.copyWith(color: colors.text3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
