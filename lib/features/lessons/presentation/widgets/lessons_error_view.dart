import 'package:flutter/material.dart';

/// Список уроков не загрузился: сообщение и кнопка повтора.
class LessonsErrorView extends StatelessWidget {
  const LessonsErrorView({
    super.key,
    required this.message,
    required this.onRetryPressed,
  });

  final String message;
  final VoidCallback onRetryPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetryPressed,
            child: const Text('Повторить'),
          ),
        ],
      ),
    ),
  );
}
