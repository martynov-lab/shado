import 'package:flutter/material.dart';

/// Upload progress with a way to abort the transfer.
class UploadProgress extends StatelessWidget {
  const UploadProgress({
    super.key,
    required this.progress,
    required this.onCancelPressed,
    this.label,
  });

  /// A share from zero to one; zero means the size is unknown yet.
  final double progress;

  final VoidCallback onCancelPressed;

  /// Caption under the bar; `null` shows upload percentage.
  final String? label;

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
                label ?? 'Загрузка на сервер — ${(progress * 100).round()}%',
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
