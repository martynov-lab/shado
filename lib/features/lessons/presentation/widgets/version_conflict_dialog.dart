import 'package:flutter/material.dart';

/// Lesson version conflict dialog; `true` opens the fresh version.
class VersionConflictDialog extends StatelessWidget {
  const VersionConflictDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Lesson changed on another device'),
    content: const Text(
      'While you were editing, the lesson was saved elsewhere. The latest version is already '
      'loaded — open it and redo your edit on top.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Stay'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Open latest'),
      ),
    ],
  );
}
