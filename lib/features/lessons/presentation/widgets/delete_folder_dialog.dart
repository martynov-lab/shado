import 'package:flutter/material.dart';

/// Подтверждение удаления папки. Возвращает `true`, если удалять.
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
