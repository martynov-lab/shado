import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Lesson editor header: back, title and the main action.
class LessonEditorHeader extends StatelessWidget {
  const LessonEditorHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.onCancel,
    this.primaryLoading = false,
  });

  final String title;
  final VoidCallback onBack;

  final String primaryLabel;

  /// `null` means the action is unavailable and the button is locked.
  final VoidCallback? onPrimary;

  /// Shown on tablet and desktop only when provided.
  final VoidCallback? onCancel;

  final bool primaryLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = context.isMobile;
    final titleStyle = context.responsive(
      mobile: AppText.title,
      tablet: AppText.h2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.chevron_left,
            semanticLabel: 'Назад',
            shape: AppIconButtonShape.square,
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              title,
              style: titleStyle.copyWith(color: colors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact && onCancel != null) ...[
            AppButton(
              label: 'Отмена',
              variant: AppButtonVariant.ghost,
              onPressed: onCancel,
            ),
            const SizedBox(width: AppSpacing.s3),
          ],
          AppButton(
            label: primaryLabel,
            onPressed: onPrimary,
            loading: primaryLoading,
          ),
        ],
      ),
    );
  }
}
