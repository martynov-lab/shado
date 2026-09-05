import 'package:flutter/material.dart';

/// Topic deletion confirmation; `true` means delete.
class DeleteTopicDialog extends StatelessWidget {
  const DeleteTopicDialog({super.key, required this.topicName});

  final String topicName;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Удалить тему?'),
    content: Text(
      'Уроки темы «$topicName» переедут на «Other», а сама тема исчезнет.',
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
