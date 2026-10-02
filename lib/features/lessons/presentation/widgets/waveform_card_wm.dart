import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';

import '../../domain/entities/waveform_peaks.dart';
import '../../domain/entities/waveform_query.dart';
import 'waveform_card.dart';
import 'waveform_card_model.dart';

WaveformCardWidgetModel waveformCardWidgetModelFactory(BuildContext context) =>
    WaveformCardWidgetModel(
      WaveformCardModel(ProviderScope.containerOf(context, listen: false)),
    );

class WaveformCardWidgetModel
    extends WidgetModel<WaveformCard, WaveformCardModel> {
  WaveformCardWidgetModel(super.model);

  final ValueNotifier<AsyncState<WaveformPeaks>> _peaks = ValueNotifier(
    const AsyncPending(),
  );
  late final ValueNotifier<WaveformCard> _config = ValueNotifier(widget);
  WaveformQuery? _query;

  ValueListenable<AsyncState<WaveformPeaks>> get peaks => _peaks;

  /// The latest card parameters: the parent passes new ones on every
  /// playhead move or marker change.
  ValueListenable<WaveformCard> get config => _config;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _load();
  }

  @override
  void didUpdateWidget(WaveformCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _config.value = widget;
    _load();
  }

  @override
  void dispose() {
    _peaks.dispose();
    _config.dispose();
    super.dispose();
  }

  /// Loads the peaks again only when the file or the shown range changed.
  void _load() {
    final card = widget;
    final query = WaveformQuery(
      audioId: card.audioId,
      localPath: card.audioPath,
      durationMs: card.durationMs,
      cache: card.cachePeaks,
      // For an untrimmed file no range is set, so the wave is not refetched.
      range: card.view.isTrimmedFrom(card.durationMs) ? card.view : null,
    );
    if (query == _query) return;
    _query = query;
    _peaks.value = const AsyncPending();
    unawaited(_fetch(query));
  }

  Future<void> _fetch(WaveformQuery query) async {
    final peaks = await AsyncState.guard(() => model.loadPeaks(query));
    if (isMounted && _query == query) _peaks.value = peaks;
  }
}
