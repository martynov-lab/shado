import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Folder screen header: back, title and the author action menu.
class FolderTopBar extends StatelessWidget {
  const FolderTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.onRename,
    this.onDelete,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasMenu = onRename != null || onDelete != null;

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
            semanticLabel: 'Back',
            shape: AppIconButtonShape.square,
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              title,
              style: AppText.h2.copyWith(color: colors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMenu)
            PopupMenuButton<String>(
              icon: AppIcon(AppIcons.moreVertical, color: colors.text2),
              onSelected: (value) {
                if (value == 'rename') onRename?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onRename != null)
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete folder'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
