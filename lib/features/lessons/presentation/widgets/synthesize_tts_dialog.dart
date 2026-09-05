import 'package:flutter/material.dart';

/// Confirms replacing the chosen audio with a voice-over; `true` proceeds.
class SynthesizeTtsDialog extends StatelessWidget {
  const SynthesizeTtsDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Заменить аудио озвучкой?'),
    content: const Text(
      'Аудио уже загружено. Озвучка через ИИ заменит его, а расставленные '
      'границы сегментов сбросятся.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Озвучить'),
      ),
    ],
  );
}
