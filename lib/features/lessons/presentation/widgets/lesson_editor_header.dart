import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Шапка редактора урока: назад, заголовок и основное действие. На планшете и
/// десктопе рядом появляется «Отмена». Одна на экраны создания и правки —
/// меняются только подписи и обработчики.
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

  /// `null` — действие пока недоступно (кнопка заперта).
  final VoidCallback? onPrimary;

  /// Показывается только на планшете/десктопе, если задан.
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
