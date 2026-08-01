import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../controllers/lesson_controller.dart';
import 'lesson_labels.dart';
import 'lesson_segment_row.dart';

/// Панель со списком сегментов: заголовок с инструментами, прокручиваемый
/// список строк и — в режиме выбора — панель проигрывания выбранного отрезка.
///
/// Один виджет для боковой панели на планшете/десктопе и для модального листа на
/// телефоне: [shrinkWrap] переключает список между «занять всю высоту» и
/// «по содержимому».
class LessonSegmentsPanel extends ConsumerWidget {
  const LessonSegmentsPanel({
    super.key,
    required this.lessonId,
    this.shrinkWrap = false,
  });

  final String lessonId;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(lessonControllerProvider(lessonId)).value;
    if (state == null) return const SizedBox.shrink();
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);
    final segments = state.lesson.segments;

    final list = ListView.builder(
      shrinkWrap: shrinkWrap,
      primary: false,
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      itemCount: segments.length,
      itemBuilder: (context, index) => LessonSegmentRow(
        segment: segments[index],
        isCurrent: state.currentIndex == index,
        isPlaying: state.isSegmentPlaying(index),
        isSelecting: state.isSelecting,
        isSelected: state.isSegmentSelected(index),
        onPressed: () => controller.goToSegment(index),
        onSelectPressed: () => controller.toggleSelection(index),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Сегменты · ${state.currentIndex + 1}/${segments.length}',
                style: AppText.title.copyWith(color: colors.text),
              ),
            ),
            if (state.isSelecting) ...[
              _ToolLink(
                label: state.selection == null ? 'Выбрать все' : 'Снять',
                onTap: state.selection == null
                    ? controller.selectAll
                    : controller.clearSelection,
              ),
              const SizedBox(width: AppSpacing.s4),
              _ToolLink(label: 'Готово', onTap: controller.stopSelecting),
            ] else
              _ToolLink(
                label: 'Выбрать несколько',
                onTap: controller.startSelecting,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        if (shrinkWrap) Flexible(child: list) else Expanded(child: list),
        if (state.selection case final selection? when state.isSelecting) ...[
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${segmentsLabel(selection.length)} · '
                  '${formatPosition(state.selectionDurationMs)}',
                  style: AppText.caption.copyWith(color: colors.text2),
                ),
              ),
              AppIconButton(
                icon: Icons.repeat_rounded,
                semanticLabel: state.isSelectionLooped
                    ? 'Выключить повтор выбранного'
                    : 'Повторять выбранное',
                variant: state.isSelectionLooped
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: controller.toggleSelectionLoop,
              ),
              const SizedBox(width: AppSpacing.s2),
              AppButton(
                label: state.isSelectionPlaying
                    ? 'Стоп'
                    : 'Проиграть (${selection.length})',
                icon: state.isSelectionPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                size: AppButtonSize.sm,
                onPressed: controller.togglePlaySelection,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ToolLink extends StatelessWidget {
  const _ToolLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s1),
          child: Text(
            label,
            style: AppText.label.copyWith(color: context.colors.primary),
          ),
        ),
      ),
    );
  }
}
