import 'package:flutter/material.dart';

import '../../../lessons/domain/entities/lesson_category.dart';

/// Тема в списке админки: название и действия — переименовать и удалить.
///
/// В стиле соседних плиток раздела ([UserTile]) собрана из Material-виджетов.
class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
    required this.onRename,
    this.onDelete,
  });

  final Topic topic;
  final VoidCallback onRename;

  /// `null` — тему нельзя удалить (тема по умолчанию «Other»): сервер ответит
  /// `422`, поэтому кнопку не показываем вовсе (§8.2).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          topic.isDefault ? Icons.folder_special_outlined : Icons.label_outline,
        ),
      ),
      title: Text(topic.name, overflow: TextOverflow.ellipsis),
      subtitle: topic.isDefault ? const Text('Тема по умолчанию') : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Переименовать',
            onPressed: onRename,
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
