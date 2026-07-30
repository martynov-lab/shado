import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/audio_dto.dart';
import '../models/waveform_peaks.dart';

/// Аудио на сервере: загрузка, пики и файл.
abstract interface class AudioRemoteDataSource {
  /// Загружает файл и получает обратно всё, что нужно для разметки:
  /// длительность, контрольную сумму и пики.
  ///
  /// Ответ `200` вместо `201` означает, что такой файл уже загружался и был
  /// найден по sha256; для клиента разницы нет.
  Future<AudioDto> upload({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  });

  Future<WaveformPeaks> peaks(String audioId, {int resolution});

  /// Скачивает файл в [targetPath], докачивая оборванную загрузку.
  Future<void> download({
    required String audioId,
    required String targetPath,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  });
}

class ApiAudioRemoteDataSource implements AudioRemoteDataSource {
  const ApiAudioRemoteDataSource(this._client);

  /// Суффикс недокачанного файла: готовое имя занимает только целый файл, и
  /// плеер никогда не наткнётся на половину.
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
    // Проверяем размер до отправки: гонять 50 МБ ради ответа 413 незачем.
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
      // Отдав последний байт, ждём дольше обычного: сервер ещё декодирует
      // файл и считает пики, и только потом отвечает.
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

    // Обрыв докачиваем с того места, где остановились: сервер поддерживает
    // `Range` и отвечает `206`.
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

    // Сервер проигнорировал `Range` и прислал файл целиком — тогда и наш
    // «хвост» был лишним, но dio уже перезаписал файл с нуля.
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
