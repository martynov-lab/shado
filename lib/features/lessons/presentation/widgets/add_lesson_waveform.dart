import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/utils/duration_format.dart';

import '../../domain/entities/audio_trim.dart';
import '../controllers/add_lesson_controller.dart';
import '../controllers/add_lesson_playback_controller.dart';
import 'marker_at_playhead_checkbox.dart';
import 'waveform_card.dart';
import 'waveform_placeholder_card.dart';

/// Waveform of the chosen file with markers, trimming and a playhead.
class AddLessonWaveform extends ConsumerWidget {
  const AddLessonWaveform({
    super.key,
    required this.state,
    required this.onBoundariesChanged,
    required this.onBoundaryRemoved,
    required this.onMarkerAtPlayheadChanged,
    required this.onTrimChanged,
    required this.onTrimStart,
    required this.onTrimApply,
    required this.onTrimCancel,
  });

  final AddLessonFormState state;

  final ValueChanged<List<int>> onBoundariesChanged;
  final ValueChanged<int> onBoundaryRemoved;

  final ValueChanged<bool> onMarkerAtPlayheadChanged;

  final ValueChanged<AudioTrim> onTrimChanged;
  final VoidCallback onTrimStart;
  final VoidCallback onTrimApply;
  final VoidCallback onTrimCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (state.isUploading) {
      return const WaveformPlaceholderCard(
        height: 168,
        child: CircularProgressIndicator(),
      );
    }
    if (!state.hasWaveform) {
      return WaveformPlaceholderCard(
        height: 96,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Выберите аудио — здесь появится волна с метками границ',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    final playback = ref.watch(addLessonPlaybackProvider);
    final player = ref.read(addLessonPlaybackProvider.notifier);
    // While playing, the player drives the playhead.
    final position = ref.watch(addPlaybackPositionProvider).value;
    final playheadMs = playback.isPlaying
        ? (position?.inMilliseconds ?? playback.playheadMs)
        : playback.playheadMs;

    // Time is shown from the left edge of what is currently in the window.
    final view = state.view;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WaveformCard(
          audioId: state.audioId!,
          // The fallback waveform builder needs the file path.
          audioPath: state.audioPath,
          durationMs: state.durationMs,
          view: view,
          boundaries: state.boundaries,
          onBoundariesChanged: onBoundariesChanged,
          onBoundaryRemoved: onBoundaryRemoved,
          onSeek: player.seek,
          positionMs: playheadMs,
          showCursor: true,
          // The lesson itself will create the peaks cache next to the file.
          cachePeaks: false,
          margin: EdgeInsets.zero,
          trim: state.pendingTrim,
          onTrimChanged: onTrimChanged,
          onTrimStart: onTrimStart,
          onTrimApply: onTrimApply,
          onTrimCancel: onTrimCancel,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              tooltip: playback.isPlaying ? 'Пауза' : 'Играть с ползунка',
              // No file on disk: nothing to play even with peaks ready.
              onPressed: state.audioPath == null ? null : player.togglePlay,
              icon: Icon(playback.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Text(
              '${formatPosition(playheadMs - view.startMs)} / '
              '${formatPosition(view.durationMs)}',
              style: theme.textTheme.bodyMedium,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: MarkerAtPlayheadCheckbox(
                  value: state.markerAtPlayhead,
                  onChanged: onMarkerAtPlayheadChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_hint(state), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Hint under the waveform about available gestures and keys.
String _hint(AddLessonFormState state) {
  if (state.isTrimming) {
    return 'Тяните метки со стрелочками: затемнённые края отрежутся. '
        '«Применить» оставит только середину, «Отменить» вернёт как было. '
        'Обрезка помогает разметить середину файла, но в сохранённый урок '
        'аудио уходит целиком: края достанутся крайним кускам. '
        'Пробел — послушать';
  }
  if (state.segmentCount == 0) {
    return 'Введите текст — метки границ появятся на волне';
  }
  return 'Метка в тексте добавляет границу правее самой правой. Чтобы ставить '
      'границы на слух, включите «Метка по ползунку»: доведите плеер до паузы '
      'между фразами, поставьте на паузу и добавьте метку в тексте — граница '
      'встанет в позицию ползунка, а метки правее останутся на местах. '
      'Метки берутся за кружок сверху, ползунок — за треугольник '
      'снизу; перетаскивание в стороне от них двигает волну. Двойной тап по '
      'метке убирает её (и парную метку в тексте). Растянуть волну: щипок двумя '
      'пальцами или Ctrl + колесо мыши. Пробел — играть или пауза';
}
