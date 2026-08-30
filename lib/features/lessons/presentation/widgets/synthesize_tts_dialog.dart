import 'package:flutter/material.dart';

/// Подтверждение озвучки, когда аудио уже выбрано: синтез заменит его.
/// Возвращает `true`, если озвучивать.
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
