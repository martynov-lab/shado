import 'package:flutter/material.dart';

import 'package:shado/core/utils/duration_format.dart';

/// Панель выбранных кусков: играет их подряд или зацикливает отрезок целиком.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.selectedCount,
    required this.durationMs,
    required this.isPlaying,
    required this.isLooped,
    required this.onPlayPressed,
    required this.onLoopPressed,
    required this.onClearPressed,
  });

  /// Сколько кусков выбрано и сколько выделение звучит целиком.
  final int selectedCount;
  final int durationMs;

  /// Играет именно выделение, а не отдельный кусок мимо него.
  final bool isPlaying;

  final bool isLooped;

  final VoidCallback onPlayPressed;
  final VoidCallback onLoopPressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedCount ${_segmentsWord(selectedCount)} · '
                  '${formatPosition(durationMs)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: isLooped ? 'Выключить повтор' : 'Повторять выбранное',
                onPressed: onLoopPressed,
                isSelected: isLooped,
                icon: const Icon(Icons.repeat),
                selectedIcon: Icon(
                  Icons.repeat_on,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: onPlayPressed,
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(isPlaying ? 'Стоп' : 'Играть'),
              ),
              IconButton(
                tooltip: 'Снять выбор',
                onPressed: onClearPressed,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «1 кусок», «2 куска», «5 кусков».
String _segmentsWord(int count) {
  if (count % 100 >= 11 && count % 100 <= 14) return 'кусков';
  return switch (count % 10) {
    1 => 'кусок',
    2 || 3 || 4 => 'куска',
    _ => 'кусков',
  };
}
