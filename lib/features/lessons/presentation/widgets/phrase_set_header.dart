import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson_download.dart';
import 'lesson_download_button.dart';

/// Phrase set header: back, the title with the card counter, the download
/// and edit buttons.
class PhraseSetHeader extends StatelessWidget {
  const PhraseSetHeader({
    super.key,
    required this.title,
    required this.counter,
    required this.canEdit,
    required this.onBack,
    required this.onEdit,
    required this.download,
    required this.onToggleDownload,
  });

  final String title;

  /// Where in the deck the card is, such as `7 / 24`.
  final String counter;

  /// Shows the edit button; the server still checks the rights.
  final bool canEdit;

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final LessonDownload download;

  /// `null` disables the download button.
  final VoidCallback? onToggleDownload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                title,
                style: AppText.title.copyWith(color: colors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                counter,
                style: AppText.caption.copyWith(color: colors.text3),
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
            semanticLabel: 'Edit phrases',
            onPressed: onEdit,
          ),
        ],
      ],
    );
  }
}
