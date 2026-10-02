import 'package:flutter/material.dart';

/// Folder deletion confirmation; `true` means delete.
class DeleteFolderDialog extends StatelessWidget {
  const DeleteFolderDialog({super.key, required this.folderTitle});

  final String folderTitle;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete folder?'),
    content: Text(
      '"$folderTitle" will be deleted. The lessons stay in the catalog — only '
      'the grouping is removed.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Delete'),
      ),
    ],
  );
}
