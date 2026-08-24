import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/utils/duration_format.dart';

import '../../domain/entities/audio_trim.dart';
import '../controllers/edit_lesson_controller.dart';
import 'waveform_card.dart';

/// Волна с ползунком и кнопкой воспроизведения: аудио играет с того места,
/// куда поставили ползунок, повторное нажатие ставит на паузу.
///
/// Позицию плеера читает сам — иначе её тиканье перестраивало бы всю форму
/// правки. Остальное приходит данными и колбэками.
class EditLessonWaveform extends ConsumerWidget {
  const EditLessonWaveform({
    super.key,
    required this.lessonId,
    required this.state,
    required this.onPlayPressed,
    required this.onSeek,
    required this.onBoundariesChanged,
    required this.onBoundaryRemoved,
    required this.onTrimChanged,
    required this.onTrimStart,
    required this.onTrimApply,
    required this.onTrimCancel,
  });

  /// Нужен только чтобы подписаться на позицию своего плеера.
  final String lessonId;

  final EditLessonState state;

  final VoidCallback onPlayPressed;
  final ValueChanged<int> onSeek;
  final ValueChanged<List<int>> onBoundariesChanged;
  final ValueChanged<int> onBoundaryRemoved;

  final ValueChanged<AudioTrim> onTrimChanged;
  final VoidCallback onTrimStart;
  final VoidCallback onTrimApply;
  final VoidCallback onTrimCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Пока играет, ползунок ведёт сам плеер; на паузе он стоит там, где его
    // оставили.
    final position = ref.watch(editPlaybackPositionProvider(lessonId)).value;
    final playheadMs = state.isPlaying
        ? (position?.inMilliseconds ?? state.playheadMs)
        : state.playheadMs;

    // Время показываем от левого края того, что сейчас в окне: после обрезки
    // урок начинается с нуля, а во время обрезки — начало файла.
    final view = state.view;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WaveformCard(
          audioId: state.lesson.audioId,
          audioPath: state.lesson.audioPath,
          durationMs: state.lesson.durationMs,
          view: view,
          boundaries: state.boundaries,
          onBoundariesChanged: onBoundariesChanged,
          onBoundaryRemoved: onBoundaryRemoved,
          onSeek: onSeek,
          positionMs: playheadMs,
          showCursor: true,
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
              tooltip: state.isPlaying ? 'Пауза' : 'Играть с ползунка',
              onPressed: onPlayPressed,
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Text(
              '${formatPosition(playheadMs - view.startMs)} / '
              '${formatPosition(view.durationMs)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
