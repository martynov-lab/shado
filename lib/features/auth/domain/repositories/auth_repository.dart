import '../entities/auth_user.dart';

/// Sign-in, sign-up and the current session.
abstract interface class AuthRepository {
  /// Who is signed in right now; `null` when there is no session.
  AuthUser? get currentUser;

  /// Signals that the server rejected a refresh and the session ended.
  Stream<void> get sessionExpired;

  Future<AuthUser> register({
    required String email,
    required String password,
    String? name,
  });

  Future<AuthUser> login({required String email, required String password});

  /// Restores a session from the refresh token; `null` needs the login screen.
  Future<AuthUser?> restoreSession();

  /// Re-reads the current user from the server.
  Future<AuthUser> refreshCurrentUser();

  /// Updates the profile; a `null` field is left untouched.
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  });

  /// Ends the session on the server and locally; network errors are ignored.
  Future<void> logout();
}
