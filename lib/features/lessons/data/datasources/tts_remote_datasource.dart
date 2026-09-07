import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/tts_quota.dart';
import '../../domain/entities/tts_voice.dart';
import '../models/audio_dto.dart';

/// A voice sample: the audio itself plus what it says.
typedef TtsPreviewResponse = ({AudioDto audio, String text, bool cached});

/// AI voice-over; the response has the same shape as an audio upload.
abstract interface class TtsRemoteDataSource {
  /// Synthesizes speech for [text] with the chosen voice and accent.
  Future<AudioDto> synthesize({
    required String text,
    String? voice,
    String? accent,
    CancelToken? cancelToken,
  });

  /// Voices the provider offers for the studied language.
  Future<TtsVoices> voices();

  /// Speaks a server-picked phrase in [voice] — for listening only.
  Future<TtsPreviewResponse> preview({required String voice, String? accent});

  /// Remaining free voice-over quota.
  Future<TtsQuota> quota();
}

class ApiTtsRemoteDataSource implements TtsRemoteDataSource {
  const ApiTtsRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<AudioDto> synthesize({
    required String text,
    String? voice,
    String? accent,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.post(
      '/v1/tts/synthesize',
      // The language comes from the profile; only voice and accent go here.
      data: {'text': text, 'voice': ?voice, 'accent': ?accent},
      cancelToken: cancelToken,
      // Synthesis takes seconds — wait longer than for a regular request.
      options: Options(receiveTimeout: AppConfig.audioTimeout),
    );
    return AudioDto.fromJson(response.data!);
  }

  @override
  Future<TtsVoices> voices() async {
    final json = await _client.get('/v1/tts/voices');
    final raw = (json['voices'] ?? json['items']) as List<dynamic>? ?? const [];
    return TtsVoices(
      items: [
        for (final voice in raw)
          TtsVoice.fromJson(Map<String, dynamic>.from(voice as Map)),
      ],
      defaultVoice: json['default_voice'] as String?,
    );
  }

  @override
  Future<TtsPreviewResponse> preview({
    required String voice,
    String? accent,
  }) async {
    final response = await _client.post(
      '/v1/tts/preview',
      data: {'voice': voice, 'accent': ?accent},
      options: Options(receiveTimeout: AppConfig.audioTimeout),
    );
    final json = response.data!;
    return (
      audio: AudioDto.fromJson(json),
      text: json['text'] as String? ?? '',
      cached: json['cached'] as bool? ?? false,
    );
  }

  @override
  Future<TtsQuota> quota() async {
    final json = await _client.get('/v1/tts/quota');
    return TtsQuota.fromJson(json);
  }
}
