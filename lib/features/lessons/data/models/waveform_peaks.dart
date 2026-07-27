/// Прореженные пики аудио для отрисовки волны.
///
/// Значения нормализованы: [maxima] в диапазоне `0..1`, [minima] — `-1..0`.
class WaveformPeaks {
  const WaveformPeaks({required this.minima, required this.maxima});

  final List<double> minima;
  final List<double> maxima;

  int get length => maxima.length;

  bool get isEmpty => maxima.isEmpty;
}
