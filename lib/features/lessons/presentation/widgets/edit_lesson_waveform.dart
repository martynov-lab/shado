import 'package:flutter/material.dart';

import 'package:shado/core/utils/duration_format.dart';

import '../../domain/entities/audio_trim.dart';
import '../screens/edit_lesson/edit_lesson_state.dart';
import 'marker_at_playhead_checkbox.dart';
import 'waveform_card.dart';

/// Waveform with a playhead and a play button on the editor screen.
class EditLessonWaveform extends StatelessWidget {
  const EditLessonWaveform({
    super.key,
    required this.state,
    required this.playheadMs,
    required this.onPlayPressed,
    required this.onSeek,
    required this.onBoundariesChanged,
    required this.onBoundaryRemoved,
    required this.onMarkerAtPlayheadChanged,
    required this.onTrimChanged,
    required this.onTrimStart,
    required this.onTrimApply,
    required this.onTrimCancel,
  });

  final EditLessonState state;

  /// Playhead in file milliseconds.
  final int playheadMs;

  final VoidCallback onPlayPressed;
  final ValueChanged<int> onSeek;
  final ValueChanged<List<int>> onBoundariesChanged;
  final ValueChanged<int> onBoundaryRemoved;

  final ValueChanged<bool> onMarkerAtPlayheadChanged;

  final ValueChanged<AudioTrim> onTrimChanged;
  final VoidCallback onTrimStart;
  final VoidCallback onTrimApply;
  final VoidCallback onTrimCancel;

  @override
  Widget build(BuildContext context) {
    // Time is shown from the left edge of what is currently in the window.
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
              tooltip: state.isPlaying ? 'Pause' : 'Play from playhead',
              onPressed: onPlayPressed,
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Text(
              '${formatPosition(playheadMs - view.startMs)} / '
              '${formatPosition(view.durationMs)}',
              style: Theme.of(context).textTheme.bodyMedium,
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
      ],
    );
  }
}
