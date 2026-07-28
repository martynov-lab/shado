import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/waveform_datasource.dart';
import '../../data/models/waveform_peaks.dart';
import 'lesson_providers.dart';

/// Пики волны. Их считает сервер, поэтому запрос — это `audio_id`, отрезок и
/// разрешение; локальный путь нужен только запасному пути на случай офлайна.
///
/// Отрезок входит в ключ провайдера: у обрезанной дорожки своя, более
/// подробная волна.
final waveformPeaksProvider = FutureProvider.autoDispose
    .family<WaveformPeaks, WaveformQuery>((ref, query) {
      return ref.watch(waveformDataSourceProvider).loadPeaks(query);
    });
