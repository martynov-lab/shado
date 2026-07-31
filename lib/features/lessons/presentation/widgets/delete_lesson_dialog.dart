import 'package:flutter/material.dart';

/// Подтверждение удаления урока. Возвращает `true`, если удалять.
class DeleteLessonDialog extends StatelessWidget {
  const DeleteLessonDialog({super.key, required this.lessonTitle});

  final String lessonTitle;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Удалить урок?'),
    content: Text('«$lessonTitle» и его аудио будут удалены навсегда.'),
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
