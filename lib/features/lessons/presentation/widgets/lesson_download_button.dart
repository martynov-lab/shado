import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson_download.dart';

/// Downloads a lesson for offline study or removes the download; shows the
/// progress while the audio is transferred.
class LessonDownloadButton extends StatelessWidget {
  const LessonDownloadButton({
    super.key,
    required this.download,
    required this.onPressed,
    this.size = AppButtonSize.md,
  });

  final LessonDownload download;

  /// `null` disables the button, e.g. offline before a download.
  final VoidCallback? onPressed;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    return switch (download) {
      Downloading(:final progress) => Semantics(
        label: 'Downloading',
        child: SizedBox.square(
          dimension: switch (size) {
            AppButtonSize.sm => AppSizes.controlSm,
            AppButtonSize.md => AppSizes.controlMd,
            AppButtonSize.lg => AppSizes.controlLg,
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s2),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
        ),
      ),
      Downloaded() => AppIconButton(
        icon: Icons.download_done_rounded,
        semanticLabel: 'Remove download',
        size: size,
        onPressed: onPressed,
      ),
      NotDownloaded() => AppIconButton(
        icon: Icons.download_rounded,
        semanticLabel: 'Download for offline',
        size: size,
        onPressed: onPressed,
      ),
    };
  }
}
