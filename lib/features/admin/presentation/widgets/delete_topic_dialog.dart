import 'package:flutter/material.dart';

/// Topic deletion confirmation; `true` means delete.
class DeleteTopicDialog extends StatelessWidget {
  const DeleteTopicDialog({super.key, required this.topicName});

  final String topicName;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete topic?'),
    content: Text(
      'Lessons of the topic "$topicName" will move to "Other", and the topic will be removed.',
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
