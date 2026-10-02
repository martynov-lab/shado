import 'dart:convert';

/// Downsampled audio peaks: [maxima] in `0..1`, [minima] in `-1..0`.
class WaveformPeaks {
  const WaveformPeaks({required this.minima, required this.maxima});

  /// Parses a peaks response; the point count comes from the arrays.
  factory WaveformPeaks.fromJson(Map<String, dynamic> json) => WaveformPeaks(
    minima: decodePeaks(json['minima'] as String? ?? ''),
    maxima: decodePeaks(json['maxima'] as String? ?? ''),
  );

  final List<double> minima;
  final List<double> maxima;

  int get length => maxima.length;

  bool get isEmpty => maxima.isEmpty;
}

/// Decodes peaks: base64 → int8 → `-1..1`.
List<double> decodePeaks(String encoded) {
  if (encoded.isEmpty) return const [];
  final bytes = base64Decode(encoded);
  final signed = bytes.buffer.asInt8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  return [for (final value in signed) value / 127.0];
}
