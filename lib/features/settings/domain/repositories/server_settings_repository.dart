/// Settings stored on the server and shared by all users.
abstract interface class ServerSettingsRepository {
  /// How many repeats of every segment mark a lesson as done.
  Future<int> getCompletionReps();

  /// Returns the value the server actually saved.
  Future<int> setCompletionReps(int reps);
}
