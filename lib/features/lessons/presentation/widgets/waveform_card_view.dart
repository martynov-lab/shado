import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';

import '../../domain/entities/audio_trim.dart';
import '../../domain/entities/waveform_peaks.dart';
import 'trim_bar.dart';
import 'waveform_editor.dart';

/// The waveform card for loaded (or loading) [peaks]. With [onTrimStart] a
/// trim bar appears underneath.
class WaveformCardView extends StatelessWidget {
  const WaveformCardView({
    super.key,
    required this.peaks,
    required this.view,
    required this.boundaries,
    required this.onBoundariesChanged,
    this.onBoundaryRemoved,
    this.onSeek,
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

  final AsyncState<WaveformPeaks> peaks;

  /// File range being shown.
  final AudioTrim view;

  final List<int> boundaries;
  final ValueChanged<List<int>> onBoundariesChanged;

  /// Removes an inner marker on a double tap; `null` forbids removal.
  final ValueChanged<int>? onBoundaryRemoved;

  /// When set, a playhead appears on the waveform.
  final ValueChanged<int>? onSeek;

  final int positionMs;
  final int? activeSegmentIndex;
  final bool showCursor;
  final double height;
  final EdgeInsets margin;

  /// Range that survives trimming; `null` when trimming is off.
  final AudioTrim? trim;

  final ValueChanged<AudioTrim>? onTrimChanged;

  /// When set, a trim button appears under the waveform.
  final VoidCallback? onTrimStart;

  final VoidCallback? onTrimApply;
  final VoidCallback? onTrimCancel;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin,
      // No clip here: the painter clips the wave and handles overflow the edge.
      clipBehavior: Clip.none,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kWaveCornerRadius)),
      ),
      child: SizedBox(
        height: height,
        child: switch (peaks) {
          AsyncPending() => const Center(child: CircularProgressIndicator()),
          AsyncFailed(:final error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Waveform unavailable: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          AsyncReady(:final value) => WaveformEditor(
            peaks: value,
            view: view,
            boundaries: boundaries,
            positionMs: positionMs,
            activeSegmentIndex: activeSegmentIndex,
            showCursor: showCursor,
            height: height,
            onBoundariesChanged: onBoundariesChanged,
            onBoundaryRemoved: onBoundaryRemoved,
            onSeek: onSeek,
            trim: trim,
            onTrimChanged: onTrimChanged,
          ),
        },
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
          child: TrimBar(
            trim: trim,
            isEnabled: peaks is AsyncReady,
            onStartPressed: onTrimStart,
            onApplyPressed: onTrimApply,
            onCancelPressed: onTrimCancel,
          ),
        ),
      ],
    );
  }
}
