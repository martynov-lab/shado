import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/waveform_peaks.dart';
import 'lesson_providers.dart';

/// Пики волны для аудио урока. Извлечение долгое, поэтому результат живёт,
/// пока открыт экран урока.
final waveformPeaksProvider = FutureProvider.autoDispose
    .family<WaveformPeaks, String>((ref, audioPath) {
      return ref.watch(waveformDataSourceProvider).loadPeaks(audioPath);
    });
