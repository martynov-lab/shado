import 'package:flutter/material.dart';

/// Урок правили на другом устройстве.
///
/// Свежая версия уже в кеше — предлагаем открыть её и переписать правку
/// поверх: молча затирать чужие изменения нельзя. Возвращает `true`, если
/// открыть свежую версию.
class VersionConflictDialog extends StatelessWidget {
  const VersionConflictDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Урок изменён на другом устройстве'),
    content: const Text(
      'Пока вы правили, урок сохранили в другом месте. Свежая версия уже '
      'загружена — откройте её и повторите правку поверх.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Остаться'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Открыть свежую'),
      ),
    ],
  );
}
