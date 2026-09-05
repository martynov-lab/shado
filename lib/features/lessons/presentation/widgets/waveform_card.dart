import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/waveform_datasource.dart';
import '../../domain/entities/audio_trim.dart';
import '../controllers/waveform_controller.dart';
import 'trim_bar.dart';
import 'waveform_editor.dart';

/// Waveform card: it fetches peaks itself and shows the loading state.
/// With [onTrimStart] a trim bar appears underneath.
class WaveformCard extends ConsumerWidget {
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
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    // For an untrimmed file no range is set, so the wave is not refetched.
    final peaksAsync = ref.watch(
      waveformPeaksProvider(
        WaveformQuery(
          audioId: audioId,
          localPath: audioPath,
          durationMs: durationMs,
          cache: cachePeaks,
          range: view.isTrimmedFrom(durationMs) ? view : null,
        ),
      ),
    );
    final card = Card(
      margin: margin,
      // No clip here: the painter clips the wave and handles overflow the edge.
      clipBehavior: Clip.none,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kWaveCornerRadius)),
      ),
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
            onBoundaryRemoved: onBoundaryRemoved,
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
          child: TrimBar(
            trim: trim,
            isEnabled: peaksAsync.hasValue,
            onStartPressed: onTrimStart,
            onApplyPressed: onTrimApply,
            onCancelPressed: onTrimCancel,
          ),
        ),
      ],
    );
  }
}
