import 'package:flutter/material.dart';

/// Folder deletion confirmation; `true` means delete.
class DeleteFolderDialog extends StatelessWidget {
  const DeleteFolderDialog({super.key, required this.folderTitle});

  final String folderTitle;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Удалить папку?'),
    content: Text(
      '«$folderTitle» будет удалена. Уроки останутся в каталоге — снимется '
      'только группировка.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Удалить'),
      ),
    ],
  );
}
