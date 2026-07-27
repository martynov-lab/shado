import 'package:flutter/material.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/segment.dart';

/// Кусок урока: текст, тумблер play/pause и тумблер зацикливания.
class SegmentTile extends StatelessWidget {
  const SegmentTile({
    super.key,
    required this.segment,
    required this.isActive,
    required this.isPlaying,
    required this.isLooped,
    required this.onPlayPressed,
    required this.onLoopPressed,
  });

  final Segment segment;
  final bool isActive;
  final bool isPlaying;
  final bool isLooped;
  final VoidCallback onPlayPressed;
  final VoidCallback onLoopPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isActive ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(segment.text, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${segment.index + 1}. '
                    '${formatPosition(segment.startMs)} – '
                    '${formatPosition(segment.endMs)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isPlaying ? 'Пауза' : 'Играть',
              onPressed: onPlayPressed,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: isLooped ? 'Выключить повтор' : 'Повторять',
              onPressed: onLoopPressed,
              isSelected: isLooped,
              icon: const Icon(Icons.repeat),
              selectedIcon: Icon(
                Icons.repeat_on,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
