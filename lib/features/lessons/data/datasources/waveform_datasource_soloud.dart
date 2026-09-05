import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_trim.dart';
import '../models/waveform_peaks.dart';
import 'waveform_datasource.dart';

/// Waveform peaks via `flutter_soloud` on Windows/Linux; reads mp3, wav,
/// flac and ogg.
class SoLoudWaveformDataSource implements WaveformDataSource {
  const SoLoudWaveformDataSource();

  @override
  Future<WaveformPeaks> loadPeaks(WaveformQuery query) async {
    final audioPath = query.localPath;
    if (audioPath == null) {
      throw const AudioFailure('Файл ещё не скачан — волну строить не из чего');
    }
    final resolution = query.resolution;
    final range = query.range;
    final cache = query.cache;
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
        // endTime of -1 means the end of the file.
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

  /// Normalizes the envelope to `0..1` against the loudest point.
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

  // --- Cache ---------------------------------------------------------------

  static const int _cacheMagic = 0x53485044; // 'SHPD'

  /// Cache file: one for the whole file and one per trimmed range.
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
      // A cache with a different resolution or a broken one is recomputed.
      if (length != resolution || bytes.lengthInBytes != 8 + length * 4) {
        return null;
      }
      return Float32List.sublistView(bytes, 8);
    } catch (_) {
      // A broken cache is recomputed.
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
      // The cache is an optimization; the waveform builds without it.
    }
  }
}
