import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/waveform_datasource.dart';
import '../../data/models/waveform_peaks.dart';
import 'lesson_providers.dart';

/// Waveform peaks by query; the range is part of the provider key.
final waveformPeaksProvider = FutureProvider.autoDispose
    .family<WaveformPeaks, WaveformQuery>((ref, query) {
      return ref.watch(waveformDataSourceProvider).loadPeaks(query);
    });
