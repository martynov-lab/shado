import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_snackbar_content.dart';

export 'package:shado/widgets/app_snackbar_content.dart'
    show AppSnackbarVariant;

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
        content: AppSnackbarContent(
          message: message,
          variant: variant,
          actionLabel: actionLabel,
          onActionPressed: onAction,
        ),
      ),
    );
}
