import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Список уроков не загрузился: сообщение и кнопка повтора.
class LessonsErrorView extends StatelessWidget {
  const LessonsErrorView({
    super.key,
    required this.message,
    required this.onRetryPressed,
  });

  final String message;
  final VoidCallback onRetryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              AppIcons.refresh,
              size: AppSizes.iconLg,
              color: colors.text3,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: colors.text2),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(label: 'Повторить', onPressed: onRetryPressed),
          ],
        ),
      ),
    );
  }
}
