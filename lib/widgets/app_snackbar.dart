import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_button.dart';

/// Тон сообщения.
enum AppSnackbarVariant { neutral, success, warning, danger }

/// Показывает всплывающее сообщение в оформлении Shadowing.
///
/// Фон берётся из «мягкой» пары семантического цвета, а текст — из [AppColors.text]:
/// насыщенный success на светло-зелёном не дотягивал бы по контрасту, поэтому
/// смысл несут иконка и заливка, а читаемость — обычный цвет текста.
///
/// ```dart
/// showAppSnackbar(context, message: 'Урок сохранён', variant: AppSnackbarVariant.success);
/// ```
void showAppSnackbar(
  BuildContext context, {
  required String message,
  AppSnackbarVariant variant = AppSnackbarVariant.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = AppDurations.toast,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        // Всё оформление внутри контента: так снек получает нашу тень e3,
        // а не плоскую материаловскую.
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(AppSpacing.s4),
        behavior: SnackBarBehavior.floating,
        content: _AppSnackbarContent(
          message: message,
          variant: variant,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
}

class _AppSnackbarContent extends StatelessWidget {
  const _AppSnackbarContent({
    required this.message,
    required this.variant,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackbarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final (Color background, Color accent, Color foreground, IconData icon) =
        switch (variant) {
          AppSnackbarVariant.neutral => (
            c.surfaceInv,
            c.textInv,
            c.textInv,
            Icons.info_outline_rounded,
          ),
          AppSnackbarVariant.success => (
            c.successSoft,
            c.success,
            c.text,
            Icons.check_circle_outline_rounded,
          ),
          AppSnackbarVariant.warning => (
            c.warningSoft,
            c.warning,
            c.text,
            Icons.warning_amber_rounded,
          ),
          AppSnackbarVariant.danger => (
            c.dangerSoft,
            c.danger,
            c.text,
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
          if (actionLabel != null) ...[
            const SizedBox(width: AppSpacing.s3),
            AppButton(
              label: actionLabel!,
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction?.call();
              },
            ),
          ],
        ],
      ),
    );
  }
}
