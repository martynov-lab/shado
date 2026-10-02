import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'folder_top_bar.dart';

/// Message shown when a folder fails to load.
class FolderErrorView extends StatelessWidget {
  const FolderErrorView({
    super.key,
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        FolderTopBar(title: 'Folder', onBack: onBack),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: colors.text2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
