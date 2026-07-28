import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/waveform_peaks.dart';
import 'lesson_providers.dart';

/// Какое аудио и с кешем ли считать: у выбранного, но ещё не импортированного
/// файла кеш пиков рядом не создаём.
typedef WaveformRequest = ({String audioPath, bool cache});

/// Пики волны для аудио урока. Извлечение долгое, поэтому результат живёт,
/// пока открыт экран урока.
final waveformPeaksProvider = FutureProvider.autoDispose
    .family<WaveformPeaks, WaveformRequest>((ref, request) {
      return ref
          .watch(waveformDataSourceProvider)
          .loadPeaks(request.audioPath, cache: request.cache);
    });
