import 'package:flutter/material.dart';

import 'package:shado/core/utils/duration_format.dart';

import '../../domain/entities/audio_trim.dart';

/// Trim bar under the waveform: a trim button, or apply and cancel.
class TrimBar extends StatelessWidget {
  const TrimBar({
    super.key,
    required this.trim,
    required this.isEnabled,
    required this.onStartPressed,
    required this.onApplyPressed,
    required this.onCancelPressed,
  });

  /// Range that survives trimming; `null` before trimming starts.
  final AudioTrim? trim;

  /// The waveform has not arrived — there is nothing to trim.
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
