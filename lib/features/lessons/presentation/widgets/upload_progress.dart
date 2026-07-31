import 'package:flutter/material.dart';

/// Ход отправки файла на сервер. Полсотни мегабайт летят не мгновенно, поэтому
/// показываем прогресс и даём прервать загрузку.
class UploadProgress extends StatelessWidget {
  const UploadProgress({
    super.key,
    required this.progress,
    required this.onCancelPressed,
  });

  /// Доля от нуля до единицы; ноль — размер ещё неизвестен.
  final double progress;

  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress == 0 ? null : progress),
              const SizedBox(height: 6),
              Text(
                'Загрузка на сервер — ${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(onPressed: onCancelPressed, child: const Text('Отменить')),
      ],
    );
  }
}
