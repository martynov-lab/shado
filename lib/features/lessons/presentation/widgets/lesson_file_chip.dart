import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'lesson_file_chip_shell.dart';
import 'upload_progress.dart';

/// Audio chip: file picking or voice-over, upload progress and the file name.
class LessonFileChip extends StatelessWidget {
  const LessonFileChip({
    super.key,
    required this.fileName,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPick,
    required this.onCancelUpload,
    this.onSynthesize,
    this.canSynthesize = true,
    this.isSynthesizing = false,
    this.detail,
    this.helper,
  });

  /// Chosen file name; `null` when no file was picked.
  final String? fileName;

  /// Caption under the name, for example the duration.
  final String? detail;

  final bool isUploading;
  final double uploadProgress;

  /// An AI voice-over is running rather than a file upload.
  final bool isSynthesizing;

  /// Picks or replaces the file; `null` locks the action during an upload.
  final VoidCallback? onPick;
  final VoidCallback onCancelUpload;

  /// Runs an AI voice-over; `null` locks the button.
  final VoidCallback? onSynthesize;

  /// Whether voice-over is available to this author; `false` hides the button.
  final bool canSynthesize;

  /// Hint about supported formats shown before a file is picked.
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isUploading) {
      return LessonFileChipShell(
        child: UploadProgress(
          progress: uploadProgress,
          onCancelPressed: onCancelUpload,
          label: isSynthesizing ? 'Voicing the text with AI…' : null,
        ),
      );
    }

    if (fileName == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Choose audio',
                  icon: Icons.audiotrack,
                  variant: AppButtonVariant.secondary,
                  onPressed: onPick,
                ),
              ),
              if (canSynthesize) ...[
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: AppButton(
                    label: 'Voice with AI',
                    icon: Icons.auto_awesome,
                    variant: AppButtonVariant.secondary,
                    onPressed: onSynthesize,
                  ),
                ),
              ],
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(helper!, style: AppText.caption.copyWith(color: colors.text3)),
          ],
        ],
      );
    }

    return LessonFileChipShell(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(
              Icons.music_note,
              size: AppSizes.iconMd,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName!,
                  style: AppText.label.copyWith(color: colors.text),
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: AppText.caption.copyWith(color: colors.text3),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          // Voice-over is available with a file chosen too — it replaces it.
          if (canSynthesize) ...[
            AppButton(
              label: 'Voice with AI',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: onSynthesize,
            ),
            const SizedBox(width: AppSpacing.s2),
          ],
          AppButton(
            label: 'Replace',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}
