import 'package:elementary/elementary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/lesson_providers.dart';

import '../../domain/entities/waveform_peaks.dart';
import '../../domain/entities/waveform_query.dart';
import '../../domain/repositories/waveform_repository.dart';

/// Loads the waveform peaks for the card.
class WaveformCardModel extends ElementaryModel {
  WaveformCardModel(ProviderContainer container)
    : _repository = container.read(waveformRepositoryProvider);

  final WaveformRepository _repository;

  Future<WaveformPeaks> loadPeaks(WaveformQuery query) =>
      _repository.loadPeaks(query);
}
