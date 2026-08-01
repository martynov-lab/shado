import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_button.dart';

/// Тон сообщения.
enum AppSnackbarVariant { neutral, success, warning, danger }

/// Само сообщение: заливка по тону, иконка, текст и необязательное действие.
///
/// Показывают его через `showAppSnackbar`; отдельным виджетом он нужен, чтобы
/// снек получал нашу тень e3 вместо плоской материаловской.
class AppSnackbarContent extends StatelessWidget {
  const AppSnackbarContent({
    super.key,
    required this.message,
    this.variant = AppSnackbarVariant.neutral,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final AppSnackbarVariant variant;

  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (
      Color background,
      Color accent,
      Color foreground,
      IconData icon,
    ) = switch (variant) {
      AppSnackbarVariant.neutral => (
        colors.surfaceInv,
        colors.textInv,
        colors.textInv,
        Icons.info_outline_rounded,
      ),
      AppSnackbarVariant.success => (
        colors.successSoft,
        colors.success,
        colors.text,
        Icons.check_circle_outline_rounded,
      ),
      AppSnackbarVariant.warning => (
        colors.warningSoft,
        colors.warning,
        colors.text,
        Icons.warning_amber_rounded,
      ),
      AppSnackbarVariant.danger => (
        colors.dangerSoft,
        colors.danger,
        colors.text,
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: AppSizes.overlayMaxWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.rLg,
        boxShadow: context.shadows.e3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconMd, color: accent),
          const SizedBox(width: AppSpacing.s3),
          Flexible(
            child: Text(
              message,
              style: AppText.body.copyWith(color: foreground),
            ),
          ),
          if (actionLabel case final label?) ...[
            const SizedBox(width: AppSpacing.s3),
            AppButton(
              label: label,
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onActionPressed?.call();
              },
            ),
          ],
        ],
      ),
    );
  }
}
