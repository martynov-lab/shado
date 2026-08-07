import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/lesson_controller.dart';
import 'lesson_header.dart';
import 'lesson_player_panel.dart';
import 'lesson_segments_panel.dart';
import 'lesson_transcript_panel.dart';

/// Экран урока на телефоне: шапка, текст сегмента, кнопка списка сегментов и
/// панель плеера. Список сегментов открывается модальным листом.
class LessonMobileLayout extends StatelessWidget {
  const LessonMobileLayout({
    super.key,
    required this.lessonId,
    required this.onBack,
    required this.onEdit,
  });

  final String lessonId;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              0,
            ),
            child: LessonHeader(
              lessonId: lessonId,
              onBack: onBack,
              onEdit: onEdit,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LessonTranscriptPanel(lessonId: lessonId),
                  const SizedBox(height: AppSpacing.s4),
                  _SegmentsSheetButton(lessonId: lessonId),
                  const SizedBox(height: AppSpacing.s4),
                  LessonPlayerPanel(lessonId: lessonId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка «Список сегментов N / M», открывающая модальный лист со списком.
class _SegmentsSheetButton extends ConsumerWidget {
  const _SegmentsSheetButton({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(lessonControllerProvider(lessonId)).value;
    if (state == null) return const SizedBox.shrink();
    final count = state.lesson.segmentCount;

    return Semantics(
      button: true,
      label: 'Список сегментов',
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rMd,
          side: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showAppBottomSheet<void>(
            context: context,
            title: 'Сегменты',
            builder: (sheetContext) => LessonSegmentsPanel(
              lessonId: lessonId,
              shrinkWrap: true,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.listBullets,
                  size: AppSizes.iconMd,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  'Список сегментов',
                  style: AppText.title.copyWith(color: colors.text),
                ),
                const Spacer(),
                Text(
                  '${state.currentIndex + 1} / $count',
                  style: AppText.monoTime.copyWith(color: colors.text3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
