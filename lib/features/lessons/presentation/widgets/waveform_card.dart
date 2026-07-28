import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/audio_trim.dart';
import '../controllers/waveform_controller.dart';
import 'waveform_editor.dart';

/// Карточка с волной аудио: сама тянет пики и показывает состояние загрузки.
///
/// Используется и на экране урока, и на экранах создания/правки — разметка
/// границ везде одна и та же.
///
/// Под карточкой при заданном [onTrimStart] появляется полоска обрезки: пока
/// [trim] пуст — одна кнопка «Обрезать», а в режиме обрезки — «Применить» и
/// «Отменить» рядом с длительностью того, что останется.
class WaveformCard extends ConsumerWidget {
  const WaveformCard({
    super.key,
    required this.audioPath,
    required this.durationMs,
    required this.view,
    required this.boundaries,
    required this.onBoundariesChanged,
    this.onSeek,
    this.cachePeaks = true,
    this.positionMs = 0,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 168,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.trim,
    this.onTrimChanged,
    this.onTrimStart,
    this.onTrimApply,
    this.onTrimCancel,
  });

  final String audioPath;

  /// Длительность файла целиком: по ней разложены пики.
  final int durationMs;

  /// Отрезок файла, который показываем. В режиме обрезки — файл целиком,
  /// чтобы обрезанное можно было вернуть.
  final AudioTrim view;

  final List<int> boundaries;
  final ValueChanged<List<int>> onBoundariesChanged;

  /// Задан — на волне появляется перетаскиваемый ползунок воспроизведения.
  final ValueChanged<int>? onSeek;

  /// Кеш пиков рядом с файлом уместен только для аудио, которое уже
  /// принадлежит приложению.
  final bool cachePeaks;

  final int positionMs;
  final int? activeSegmentIndex;
  final bool showCursor;
  final double height;
  final EdgeInsets margin;

  /// Отрезок, который останется после обрезки. `null` — обрезка не идёт.
  final AudioTrim? trim;

  final ValueChanged<AudioTrim>? onTrimChanged;

  /// Задан — под волной появляется кнопка «Обрезать».
  final VoidCallback? onTrimStart;

  final VoidCallback? onTrimApply;
  final VoidCallback? onTrimCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Для необрезанного файла отрезок не задаём: только у волны на весь файл
    // есть кеш, и переспрашивать её при каждом входе в режим обрезки незачем.
    final peaksAsync = ref.watch(
      waveformPeaksProvider((
        audioPath: audioPath,
        cache: cachePeaks,
        range: view.isTrimmedFrom(durationMs) ? view : null,
      )),
    );
    final card = Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: peaksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Волна недоступна: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          data: (peaks) => WaveformEditor(
            peaks: peaks,
            view: view,
            boundaries: boundaries,
            positionMs: positionMs,
            activeSegmentIndex: activeSegmentIndex,
            showCursor: showCursor,
            height: height,
            onBoundariesChanged: onBoundariesChanged,
            onSeek: onSeek,
            trim: trim,
            onTrimChanged: onTrimChanged,
          ),
        ),
      ),
    );
    if (onTrimStart == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Padding(
          padding: EdgeInsets.only(
            left: margin.left,
            right: margin.right,
            top: 8,
          ),
          child: _TrimBar(
            trim: trim,
            enabled: peaksAsync.hasValue,
            onStart: onTrimStart,
            onApply: onTrimApply,
            onCancel: onTrimCancel,
          ),
        ),
      ],
    );
  }
}

class _TrimBar extends StatelessWidget {
  const _TrimBar({
    required this.trim,
    required this.enabled,
    required this.onStart,
    required this.onApply,
    required this.onCancel,
  });

  final AudioTrim? trim;
  final bool enabled;
  final VoidCallback? onStart;
  final VoidCallback? onApply;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = trim;
    if (range == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: enabled ? onStart : null,
          icon: const Icon(Icons.content_cut),
          label: const Text('Обрезать'),
        ),
      );
    }
    return Row(
      children: [
        FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.check),
          label: const Text('Применить'),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onCancel, child: const Text('Отменить')),
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
