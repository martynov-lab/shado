import '../../../../core/network/api_client.dart';

/// Настройки сервиса (§12.3). Порог пройденности читают все, правит owner.
abstract interface class SettingsRemoteDataSource {
  /// `lesson_completion_reps` — сколько раз повторить каждый сегмент, чтобы
  /// урок считался пройденным.
  Future<int> getCompletionReps();

  /// Правит порог (owner, 1..1000). Возвращает актуальное значение.
  Future<int> setCompletionReps(int reps);
}

class ApiSettingsRemoteDataSource implements SettingsRemoteDataSource {
  const ApiSettingsRemoteDataSource(this._client);

  final ApiClient _client;

  static const int _fallbackReps = 10;

  @override
  Future<int> getCompletionReps() async {
    final json = await _client.get('/v1/settings');
    return (json['lesson_completion_reps'] as num?)?.toInt() ?? _fallbackReps;
  }

  @override
  Future<int> setCompletionReps(int reps) async {
    final response = await _client.patch(
      '/v1/settings',
      data: {'lesson_completion_reps': reps},
    );
    return (response.data?['lesson_completion_reps'] as num?)?.toInt() ?? reps;
  }
}
