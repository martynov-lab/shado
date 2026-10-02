import 'dart:async';

import '../../../../core/error/failures.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';
import '../usecases/sign_in.dart';

/// The session of the whole app: who is signed in and with which role.
/// Call [restore] once at startup; until then the status is `unknown`.
class AuthService {
  AuthService({
    required AuthRepository repository,
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required UpdateProfile updateProfile,
  }) : _repository = repository,
       _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _updateProfile = updateProfile;

  final AuthRepository _repository;
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final StreamController<UserSession> _changes = StreamController.broadcast();

  UserSession _session = const UserSession();
  StreamSubscription<void>? _expiredSubscription;
  Future<void>? _restoring;
  bool _restoreFailedOffline = false;

  UserSession get session => _session;

  Stream<UserSession> get changes => _changes.stream;

  /// The server was unreachable at startup, so the user has to sign in
  /// again once the connection is back.
  bool get restoreFailedOffline => _restoreFailedOffline;

  /// Checks the stored refresh token and starts listening for the server
  /// ending the session. Safe to call again: the check runs once.
  Future<void> restore() => _restoring ??= _restore();

  /// Errors (wrong password, rate limit, validation) are thrown as they are.
  Future<void> signIn({required String email, required String password}) async {
    _apply(
      UserSession.signedIn(await _signIn(email: email, password: password)),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    _apply(
      UserSession.signedIn(
        await _signUp(email: email, password: password, name: name),
      ),
    );
  }

  /// Re-reads the user from the server: the role could have been changed by
  /// the owner. A failure keeps the current session.
  Future<void> reloadUser() async {
    try {
      _apply(UserSession.signedIn(await _getCurrentUser()));
    } catch (_) {
      return;
    }
  }

  /// A `null` field is left as it is. Errors are thrown as they are.
  Future<void> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    final user = await _updateProfile(
      name: name,
      studiedLanguage: studiedLanguage,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    _apply(UserSession.signedIn(user));
  }

  /// The local session ends even if the server can't be reached.
  Future<void> signOut() async {
    try {
      await _signOut();
    } finally {
      _apply(const UserSession.signedOut());
    }
  }

  void dispose() {
    _expiredSubscription?.cancel();
    _changes.close();
  }

  Future<void> _restore() async {
    _expiredSubscription = _repository.sessionExpired.listen(
      (_) => _apply(const UserSession.signedOut()),
    );
    try {
      final user = await _repository.restoreSession();
      _apply(
        user == null
            ? const UserSession.signedOut()
            : UserSession.signedIn(user),
      );
    } on NetworkFailure {
      _restoreFailedOffline = true;
      _apply(const UserSession.signedOut());
    } catch (_) {
      _apply(const UserSession.signedOut());
    }
  }

  void _apply(UserSession session) {
    _session = session;
    _changes.add(session);
  }
}
