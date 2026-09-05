import '../../../../core/network/api_client.dart';

/// Service settings; everyone reads the completion threshold, the owner edits.
abstract interface class SettingsRemoteDataSource {
  /// `lesson_completion_reps` — how many repeats per segment mark a lesson as
  /// done.
  Future<int> getCompletionReps();

  /// Updates the threshold (1..1000) and returns the current value.
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
