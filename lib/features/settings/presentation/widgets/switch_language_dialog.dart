import 'package:flutter/material.dart';

/// Warns that the catalog changes with the language; `true` proceeds.
class SwitchLanguageDialog extends StatelessWidget {
  const SwitchLanguageDialog({super.key, required this.languageLabel});

  final String languageLabel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Switch the studied language?'),
    content: Text(
      'Lessons and folders on screens will switch to $languageLabel: the catalog is single-language. '
      'Nothing is lost — the previous lessons come back if you switch back.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Switch'),
      ),
    ],
  );
}
