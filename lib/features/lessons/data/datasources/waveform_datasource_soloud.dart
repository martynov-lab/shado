import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_trim.dart';
import '../models/waveform_peaks.dart';
import 'waveform_datasource.dart';

/// Пики волны для Windows/Linux, где `just_waveform` не работает.
///
/// `flutter_soloud` отдаёт RMS-огибающую прямо из декодера (miniaudio) в
/// отдельном изоляте, движок воспроизведения при этом не поднимается. Форма
/// получается односторонней — RMS всегда неотрицателен, — поэтому волна
/// рисуется симметрично относительно центра.
///
/// Декодер понимает mp3, wav, flac и ogg; m4a/aac он не умеет, для них волна
/// на десктопе недоступна.
class SoLoudWaveformDataSource implements WaveformDataSource {
  const SoLoudWaveformDataSource();

  @override
  Future<WaveformPeaks> loadPeaks(
    String audioPath, {
    int resolution = kWaveformResolution,
    bool cache = true,
    AudioTrim? range,
  }) async {
    if (cache) {
      final cached = await _readCache(audioPath, resolution, range);
      if (cached != null) return _toPeaks(cached);
    }

    final extension = p
        .extension(audioPath)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!kDesktopAudioExtensions.contains(extension)) {
      throw AudioFailure(
        'На этой платформе волна доступна только для '
        '${kDesktopAudioExtensions.join(', ')} — формат $extension не читается',
      );
    }

    final Float32List envelope;
    try {
      envelope = await SoLoud.instance.readSamplesFromFile(
        audioPath,
        resolution,
        // Декодер сам раскладывает нужное число отсчётов по заданному отрезку;
        // -1 у endTime означает «до конца файла».
        startTime: range == null ? 0 : range.startMs / 1000,
        endTime: range == null ? -1 : range.endMs / 1000,
        average: true,
      );
    } catch (error) {
      throw AudioFailure('Не удалось построить волновую форму', cause: error);
    }

    final normalized = _normalize(envelope);
    if (cache) await _writeCache(audioPath, normalized, range);
    return _toPeaks(normalized);
  }

  /// Тянет огибающую к `0..1` по громкости самого громкого места: RMS сам по
  /// себе даёт низкую волну, на которой не видно границ фраз.
  Float32List _normalize(Float32List envelope) {
    var peak = 0.0;
    for (final value in envelope) {
      final magnitude = value.abs();
      if (magnitude > peak) peak = magnitude;
    }
    if (peak <= 0) return Float32List(envelope.length);
    final result = Float32List(envelope.length);
    for (var i = 0; i < envelope.length; i++) {
      result[i] = (envelope[i].abs() / peak).clamp(0.0, 1.0);
    }
    return result;
  }

  WaveformPeaks _toPeaks(Float32List envelope) {
    final maxima = List<double>.filled(envelope.length, 0);
    final minima = List<double>.filled(envelope.length, 0);
    for (var i = 0; i < envelope.length; i++) {
      maxima[i] = envelope[i];
      minima[i] = -envelope[i];
    }
    return WaveformPeaks(minima: minima, maxima: maxima);
  }

  // --- Кеш -----------------------------------------------------------------
  // Декодирование целого файла занимает секунды, а урок открывают часто.

  static const int _cacheMagic = 0x53485044; // 'SHPD'

  /// У файла целиком кеш один, у каждого обрезанного отрезка — свой: волна
  /// отрезка считается по нему, поэтому и складывать её надо отдельно.
  /// Все они убираются вместе с аудио в [AudioFileDataSource.deleteAudio].
  File _cacheFile(String audioPath, AudioTrim? range) => File(
    range == null
        ? '$audioPath.peaks'
        : '$audioPath.${range.startMs}-${range.endMs}.peaks',
  );

  Future<Float32List?> _readCache(
    String audioPath,
    int resolution,
    AudioTrim? range,
  ) async {
    final file = _cacheFile(audioPath, range);
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes < 8) return null;
      final header = bytes.buffer.asByteData(bytes.offsetInBytes, 8);
      if (header.getUint32(0) != _cacheMagic) return null;
      final length = header.getUint32(4);
      // Кеш от другого разрешения или обрезанный — считаем заново.
      if (length != resolution ||
          bytes.lengthInBytes != 8 + length * 4) {
        return null;
      }
      return Float32List.sublistView(bytes, 8);
    } catch (_) {
      // Битый кеш не повод падать: пересчитаем.
      return null;
    }
  }

  Future<void> _writeCache(
    String audioPath,
    Float32List envelope,
    AudioTrim? range,
  ) async {
    try {
      final bytes = Uint8List(8 + envelope.lengthInBytes);
      bytes.buffer.asByteData()
        ..setUint32(0, _cacheMagic)
        ..setUint32(4, envelope.length);
      bytes.setRange(8, bytes.length, envelope.buffer.asUint8List());
      await _cacheFile(audioPath, range).writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Кеш — оптимизация, его отсутствие ничего не ломает.
    }
  }
}
