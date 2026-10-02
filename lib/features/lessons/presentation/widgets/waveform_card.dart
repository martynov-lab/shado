import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/audio_trim.dart';
import 'waveform_card_view.dart';
import 'waveform_card_wm.dart';

/// Waveform card: it fetches peaks itself and shows the loading state.
/// With [onTrimStart] a trim bar appears underneath.
class WaveformCard extends ElementaryWidget<WaveformCardWidgetModel> {
  const WaveformCard({
    super.key,
    required this.audioId,
    required this.durationMs,
    required this.view,
    required this.boundaries,
    required this.onBoundariesChanged,
    this.onBoundaryRemoved,
    this.audioPath,
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
  }) : super(waveformCardWidgetModelFactory);

  /// Server-side audio the peaks are fetched for.
  final String audioId;

  /// Local file copy for the fallback waveform builder.
  final String? audioPath;

  /// Duration of the whole file.
  final int durationMs;

  /// File range being shown.
  final AudioTrim view;

  final List<int> boundaries;
  final ValueChanged<List<int>> onBoundariesChanged;

  /// Removes an inner marker on a double tap; `null` forbids removal.
  final ValueChanged<int>? onBoundaryRemoved;

  /// When set, a playhead appears on the waveform.
  final ValueChanged<int>? onSeek;

  /// Whether to write the peaks cache next to the file.
  final bool cachePeaks;

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
  Widget build(WaveformCardWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.peaks, wm.config]),
      builder: (_, _) {
        final card = wm.config.value;
        return WaveformCardView(
          peaks: wm.peaks.value,
          view: card.view,
          boundaries: card.boundaries,
          onBoundariesChanged: card.onBoundariesChanged,
          onBoundaryRemoved: card.onBoundaryRemoved,
          onSeek: card.onSeek,
          positionMs: card.positionMs,
          activeSegmentIndex: card.activeSegmentIndex,
          showCursor: card.showCursor,
          height: card.height,
          margin: card.margin,
          trim: card.trim,
          onTrimChanged: card.onTrimChanged,
          onTrimStart: card.onTrimStart,
          onTrimApply: card.onTrimApply,
          onTrimCancel: card.onTrimCancel,
        );
      },
    );
  }
}
