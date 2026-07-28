import 'dart:convert';

/// Прореженные пики аудио для отрисовки волны.
///
/// Значения нормализованы: [maxima] в диапазоне `0..1`, [minima] — `-1..0`.
class WaveformPeaks {
  const WaveformPeaks({required this.minima, required this.maxima});

  /// Разбирает ответ `/v1/audio/{id}/peaks`.
  ///
  /// Фактическое число точек берётся из самих массивов, а не из поля
  /// `resolution`: сервер прореживает огибающую под запрос и вправе вернуть
  /// меньше точек, чем просили, — растягивать пришедшее должен виджет.
  factory WaveformPeaks.fromJson(Map<String, dynamic> json) => WaveformPeaks(
    minima: decodePeaks(json['minima'] as String? ?? ''),
    maxima: decodePeaks(json['maxima'] as String? ?? ''),
  );

  final List<double> minima;
  final List<double> maxima;

  int get length => maxima.length;

  bool get isEmpty => maxima.isEmpty;
}

/// Раскодирует пики: base64 → int8 → `-1..1`.
///
/// Сервер шлёт огибающую однобайтовыми значениями (2000 точек — это 4 КБ
/// вместо ~30 КБ JSON-числами), клиенту нужны доли единицы.
List<double> decodePeaks(String encoded) {
  if (encoded.isEmpty) return const [];
  final bytes = base64Decode(encoded);
  final signed = bytes.buffer.asInt8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  return [for (final value in signed) value / 127.0];
}
