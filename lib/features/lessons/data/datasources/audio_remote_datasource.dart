import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/audio_dto.dart';
import '../models/waveform_peaks.dart';

/// Server-side audio: upload, peaks and the file.
abstract interface class AudioRemoteDataSource {
  /// Uploads a file and receives its duration, checksum and peaks.
  Future<AudioDto> upload({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  });

  Future<WaveformPeaks> peaks(String audioId, {int resolution});

  /// Downloads a file into [targetPath], resuming an interrupted transfer.
  Future<void> download({
    required String audioId,
    required String targetPath,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  });
}

class ApiAudioRemoteDataSource implements AudioRemoteDataSource {
  const ApiAudioRemoteDataSource(this._client);

  /// Suffix of a partially downloaded file.
  static const String _partialSuffix = '.part';

  final ApiClient _client;

  @override
  Future<AudioDto> upload({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw AudioFailure('Файл $filePath не найден');
    }
    final size = await file.length();
    // The size is checked before uploading.
    if (size > AppConfig.maxUploadBytes) {
      throw ApiException(
        code: ApiErrorCode.payloadTooLarge,
        message:
            'Файл больше ${AppConfig.maxUploadBytes ~/ (1024 * 1024)} МБ — '
            'сервер его не примет',
        status: 413,
      );
    }

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
      ),
    });
    final response = await _client.post(
      '/v1/audio',
      data: form,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
      // Wait longer than usual: the server computes peaks after the upload.
      options: Options(
        sendTimeout: AppConfig.audioTimeout,
        receiveTimeout: AppConfig.audioTimeout,
      ),
    );
    return AudioDto.fromJson(response.data!);
  }

  @override
  Future<WaveformPeaks> peaks(String audioId, {int resolution = 2000}) async {
    final json = await _client.get(
      '/v1/audio/$audioId/peaks',
      query: {'resolution': resolution},
    );
    return WaveformPeaks.fromJson(json);
  }

  @override
  Future<void> download({
    required String audioId,
    required String targetPath,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final partial = File('$targetPath$_partialSuffix');
    final alreadyHave = await partial.exists() ? await partial.length() : 0;

    // An interrupted download is resumed with `Range`.
    final response = await _client.download(
      '/v1/audio/$audioId/file',
      partial.path,
      append: alreadyHave > 0,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
      options: Options(
        receiveTimeout: AppConfig.audioTimeout,
        headers: alreadyHave > 0 ? {'Range': 'bytes=$alreadyHave-'} : null,
      ),
    );

    // The server ignored `Range` and sent the whole file.
    if (alreadyHave > 0 && response.statusCode == 200) {
      await _redownloadWhole(audioId, partial, onProgress, cancelToken);
    }

    await partial.rename(targetPath);
  }

  Future<void> _redownloadWhole(
    String audioId,
    File partial,
    void Function(int, int)? onProgress,
    CancelToken? cancelToken,
  ) async {
    if (await partial.exists()) await partial.delete();
    await _client.download(
      '/v1/audio/$audioId/file',
      partial.path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
      options: Options(receiveTimeout: AppConfig.audioTimeout),
    );
  }
}
