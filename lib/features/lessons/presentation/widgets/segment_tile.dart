import 'package:flutter/material.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/segment.dart';

/// Кусок урока: текст, тумблеры «играть» и «повторять», а в режиме выбора —
/// ещё и галочка.
class SegmentTile extends StatelessWidget {
  const SegmentTile({
    super.key,
    required this.segment,
    required this.isActive,
    required this.isPlaying,
    required this.isLooped,
    required this.isSelecting,
    required this.isSelected,
    required this.isFocused,
    required this.onPlayPressed,
    required this.onLoopPressed,
    required this.onSelectPressed,
    required this.onPressed,
  });

  final Segment segment;

  /// Кусок заряжен в плеер — сам или как часть выбранного отрезка.
  final bool isActive;

  final bool isPlaying;
  final bool isLooped;

  /// Включён режим выбора: галочка занимает место перед текстом, а тап по
  /// плитке набирает выделение вместо перевода фокуса.
  final bool isSelecting;

  final bool isSelected;

  /// Кусок под клавиатурой: на нём сработают стрелки и пробел.
  final bool isFocused;

  final VoidCallback onPlayPressed;
  final VoidCallback onLoopPressed;
  final VoidCallback onSelectPressed;

  /// Тап по плитке вне режима выбора: делает кусок текущим для клавиатуры.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(12);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected
          ? scheme.secondaryContainer
          : (isActive ? scheme.primaryContainer : null),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        // Рамка вместо заливки: фокус клавиатуры и выбор — разные вещи, и на
        // одной плитке они могут быть одновременно.
        side: isFocused
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        // В режиме выбора тап по плитке набирает выделение: попадать по
        // галочке на телефоне неудобно.
        onTap: isSelecting ? onSelectPressed : onPressed,
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.fromLTRB(isSelecting ? 4 : 16, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelecting)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectPressed(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
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
              ),
              IconButton(
                tooltip: isPlaying ? 'Остановить' : 'Играть',
                onPressed: onPlayPressed,
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              ),
              IconButton(
                tooltip: isLooped ? 'Выключить повтор' : 'Повторять',
                onPressed: onLoopPressed,
                isSelected: isLooped,
                icon: const Icon(Icons.repeat),
                selectedIcon: Icon(Icons.repeat_on, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
