import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Folder section header: a caption and the create-folder button.
class FoldersSectionHeader extends StatelessWidget {
  const FoldersSectionHeader({super.key, this.onCreate});

  /// Creates a folder; `null` hides the button from non-authors.
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
