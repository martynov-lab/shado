import 'package:flutter/material.dart';

/// Lesson deletion confirmation; `true` means delete.
class DeleteLessonDialog extends StatelessWidget {
  const DeleteLessonDialog({super.key, required this.lessonTitle});

  final String lessonTitle;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete lesson?'),
    content: Text('"$lessonTitle" and its audio will be deleted permanently.'),
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
