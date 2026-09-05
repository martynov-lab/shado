import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_snackbar_content.dart';

export 'package:shado/widgets/app_snackbar_content.dart'
    show AppSnackbarVariant;

/// Shows a snackbar styled by the design system.
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
        // All styling lives inside the content widget.
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
