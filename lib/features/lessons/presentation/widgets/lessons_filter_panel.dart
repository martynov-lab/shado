import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/lessons_filter.dart';
import 'lessons_filter_options.dart';

/// Боковая панель фильтров на десктопе: все группы флажков сразу.
class LessonsFilterPanel extends ConsumerWidget {
  const LessonsFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeCount = ref.watch(
      lessonsFilterProvider.select((filter) => filter.activeCount),
    );

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border(
          left: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Фильтры',
                    style: AppText.title.copyWith(color: colors.text),
                  ),
                ),
                if (activeCount > 0)
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: ref.read(lessonsFilterProvider.notifier).clearFilters,
                      borderRadius: AppRadii.rSm,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s1),
                        child: Text(
                          'Сбросить',
                          style: AppText.label.copyWith(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),
            const LessonsFilterOptions(),
          ],
        ),
      ),
    );
  }
}
