import 'package:flutter/material.dart';

/// Warns that the catalog changes with the language; `true` proceeds.
class SwitchLanguageDialog extends StatelessWidget {
  const SwitchLanguageDialog({super.key, required this.languageLabel});

  final String languageLabel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Сменить изучаемый язык?'),
    content: Text(
      'Уроки и папки на экранах сменятся на $languageLabel: каталог одноязычный. '
      'Ничего не потеряется — прежние уроки вернутся, если переключиться назад.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Сменить'),
      ),
    ],
  );
}
