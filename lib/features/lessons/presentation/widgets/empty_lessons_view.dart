import 'package:flutter/material.dart';

/// Заглушка списка уроков: куда идти, если уроков ещё нет.
class EmptyLessonsView extends StatelessWidget {
  const EmptyLessonsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Уроков пока нет', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Перейдите на вкладку «Добавить», чтобы загрузить аудио '
              'и разметить текст.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
