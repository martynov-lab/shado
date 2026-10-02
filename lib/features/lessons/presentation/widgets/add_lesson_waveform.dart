import 'package:flutter/material.dart';

import 'package:shado/core/utils/duration_format.dart';

import '../../domain/entities/audio_trim.dart';
import '../screens/add_lesson/add_lesson_form_state.dart';
import 'marker_at_playhead_checkbox.dart';
import 'waveform_card.dart';
import 'waveform_placeholder_card.dart';

/// Waveform of the chosen file with markers, trimming and a playhead.
class AddLessonWaveform extends StatelessWidget {
  const AddLessonWaveform({
    super.key,
    required this.state,
    required this.isPlaying,
    required this.playheadMs,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onBoundariesChanged,
    required this.onBoundaryRemoved,
    required this.onMarkerAtPlayheadChanged,
    required this.onTrimChanged,
    required this.onTrimStart,
    required this.onTrimApply,
    required this.onTrimCancel,
  });

  final AddLessonFormState state;
  final bool isPlaying;

  /// Playhead in file milliseconds.
  final int playheadMs;

  final ValueChanged<int> onSeek;
  final VoidCallback onTogglePlay;

  final ValueChanged<List<int>> onBoundariesChanged;
  final ValueChanged<int> onBoundaryRemoved;

  final ValueChanged<bool> onMarkerAtPlayheadChanged;

  final ValueChanged<AudioTrim> onTrimChanged;
  final VoidCallback onTrimStart;
  final VoidCallback onTrimApply;
  final VoidCallback onTrimCancel;

  @override
  Widget build(BuildContext context) {
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
            'Choose audio — the waveform with boundary markers will appear here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

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
          onSeek: onSeek,
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
              tooltip: isPlaying ? 'Pause' : 'Play from playhead',
              // No file on disk: nothing to play even with peaks ready.
              onPressed: state.audioPath == null ? null : onTogglePlay,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
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
    return 'Drag the arrow markers: the dimmed edges will be cut off. '
        '"Apply" keeps only the middle, "Cancel" restores it as it was. '
        'Trimming helps mark up the middle of the file, but the saved lesson '
        'gets the whole audio: the edges go to the outer chunks. '
        'Space — listen';
  }
  if (state.segmentCount == 0) {
    return 'Enter text — boundary markers will appear on the waveform';
  }
  return 'A marker in the text adds a boundary right of the rightmost one. To set '
      'boundaries by ear, turn on "Marker at playhead": play up to the pause '
      'between phrases, pause and add a marker in the text — the boundary '
      'lands at the playhead, and markers to the right stay in place. '
      'Grab markers by the circle on top, the playhead by the triangle '
      'below; dragging elsewhere moves the waveform. A double tap on a '
      'marker removes it (and its paired marker in the text). Zoom the waveform: pinch with two '
      'fingers or Ctrl + mouse wheel. Space — play or pause';
}
