import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/tts_quota.dart';
import '../models/audio_dto.dart';

/// AI voice-over; the response has the same shape as an audio upload.
abstract interface class TtsRemoteDataSource {
  /// Synthesizes speech for [text].
  Future<AudioDto> synthesize({required String text, CancelToken? cancelToken});

  /// Remaining free voice-over quota.
  Future<TtsQuota> quota();
}

class ApiTtsRemoteDataSource implements TtsRemoteDataSource {
  const ApiTtsRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<AudioDto> synthesize({
    required String text,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.post(
      '/v1/tts/synthesize',
      data: {'text': text},
      cancelToken: cancelToken,
      // Synthesis takes seconds — wait longer than for a regular request.
      options: Options(receiveTimeout: AppConfig.audioTimeout),
    );
    return AudioDto.fromJson(response.data!);
  }

  @override
  Future<TtsQuota> quota() async {
    final json = await _client.get('/v1/tts/quota');
    return TtsQuota.fromJson(json);
  }
}
