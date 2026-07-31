import 'package:flutter/material.dart';

import 'package:shado/core/utils/duration_format.dart';

import '../../domain/entities/audio_trim.dart';

/// Полоска обрезки под волной: пока обрезка не начата — одна кнопка
/// «Обрезать», в режиме обрезки — «Применить» и «Отменить» рядом с
/// длительностью того, что останется.
class TrimBar extends StatelessWidget {
  const TrimBar({
    super.key,
    required this.trim,
    required this.isEnabled,
    required this.onStartPressed,
    required this.onApplyPressed,
    required this.onCancelPressed,
  });

  /// Отрезок, который останется. `null` — обрезка ещё не начата.
  final AudioTrim? trim;

  /// Волна ещё не пришла — обрезать нечего.
  final bool isEnabled;

  final VoidCallback? onStartPressed;
  final VoidCallback? onApplyPressed;
  final VoidCallback? onCancelPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = trim;

    if (range == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: isEnabled ? onStartPressed : null,
          icon: const Icon(Icons.content_cut),
          label: const Text('Обрезать'),
        ),
      );
    }

    return Row(
      children: [
        FilledButton.icon(
          onPressed: onApplyPressed,
          icon: const Icon(Icons.check),
          label: const Text('Применить'),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onCancelPressed, child: const Text('Отменить')),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Останется ${formatPosition(range.durationMs)}',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
