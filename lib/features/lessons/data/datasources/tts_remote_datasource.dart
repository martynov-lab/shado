import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/audio_dto.dart';

/// Озвучка текста через ИИ (Google Cloud TTS, см. `TTS_CLIENT_SPEC.md`).
///
/// Для клиента это второй вход в тот же результат, что и загрузка файла
/// (`POST /v1/audio`): ответ — та же форма (ссылка на файл + пики), поэтому
/// разбирается в [AudioDto]. Язык и голос задаёт сервер, клиент их не шлёт.
abstract interface class TtsRemoteDataSource {
  /// Синтезирует речь по [text]. Файл затем скачивается тем же эндпоинтом
  /// `GET /v1/audio/{id}/file`, что и обычное аудио.
  Future<AudioDto> synthesize({required String text, CancelToken? cancelToken});
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
      // Синтез идёт несколько секунд — ждём дольше обычного запроса.
      options: Options(receiveTimeout: AppConfig.audioTimeout),
    );
    // Поле `cached` в ответе на поведение клиента не влияет — [AudioDto] его
    // просто не читает.
    return AudioDto.fromJson(response.data!);
  }
}
