import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson_download.dart';
import '../screens/lesson/lesson_state.dart';
import 'lesson_download_button.dart';

/// Lesson screen header: back, the title with a subtitle, the download and
/// edit buttons.
class LessonHeader extends StatelessWidget {
  const LessonHeader({
    super.key,
    required this.state,
    required this.canEdit,
    required this.onBack,
    required this.onEdit,
    required this.download,
    required this.onToggleDownload,
  });

  final LessonState state;

  /// Shows the edit button; the server still checks the rights.
  final bool canEdit;

  final VoidCallback onBack;
  final VoidCallback onEdit;

  /// Offline availability shown by the download button.
  final LessonDownload download;

  /// `null` disables the download button.
  final VoidCallback? onToggleDownload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = state.lesson;

    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_rounded,
          semanticLabel: 'Back',
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lesson.title,
                style: AppText.title.copyWith(color: colors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _subtitle(state),
                style: AppText.caption.copyWith(color: colors.text3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        LessonDownloadButton(download: download, onPressed: onToggleDownload),
        if (canEdit) ...[
          const SizedBox(width: AppSpacing.s3),
          AppIconButton(
            icon: Icons.edit_outlined,
            semanticLabel: 'Edit segmentation',
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
      'segment ${state.currentIndex + 1} of ${lesson.segmentCount}',
      if (lesson.level != null) lesson.level!.wire.toUpperCase(),
    ].join(' · ');
  }
}
