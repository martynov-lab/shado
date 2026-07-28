import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/waveform_controller.dart';
import 'waveform_editor.dart';

/// Карточка с волной аудио: сама тянет пики и показывает состояние загрузки.
///
/// Используется и на экране урока, и на экранах создания/правки — разметка
/// границ везде одна и та же.
class WaveformCard extends ConsumerWidget {
  const WaveformCard({
    super.key,
    required this.audioPath,
    required this.durationMs,
    required this.boundaries,
    required this.onBoundariesChanged,
    this.onSeek,
    this.cachePeaks = true,
    this.positionMs = 0,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 168,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final String audioPath;
  final int durationMs;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peaksAsync = ref.watch(
      waveformPeaksProvider((audioPath: audioPath, cache: cachePeaks)),
    );
    return Card(
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
            durationMs: durationMs,
            boundaries: boundaries,
            positionMs: positionMs,
            activeSegmentIndex: activeSegmentIndex,
            showCursor: showCursor,
            height: height,
            onBoundariesChanged: onBoundariesChanged,
            onSeek: onSeek,
          ),
        ),
      ),
    );
  }
}
