import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Заголовок секции папок в списке уроков: подпись «Папки» и — у авторов —
/// кнопка создания новой папки.
class FoldersSectionHeader extends StatelessWidget {
  const FoldersSectionHeader({super.key, this.onCreate});

  /// Создать папку. `null` — у зрителя без прав автора кнопки нет.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s3,
        right: AppSpacing.s1,
        top: AppSpacing.s1,
        bottom: AppSpacing.s1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Папки',
              style: AppText.caption.copyWith(color: colors.text3),
            ),
          ),
          if (onCreate != null)
            AppButton(
              label: 'Папка',
              icon: Icons.add,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: onCreate,
            ),
        ],
      ),
    );
  }
}
