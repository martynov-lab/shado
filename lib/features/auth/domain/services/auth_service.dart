import 'dart:async';

import '../../../../core/network/network_monitor.dart';
import '../entities/auth_user.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';
import '../usecases/sign_in.dart';

/// The session of the whole app: who is signed in and with which role.
/// Call [restore] once at startup; until then the status is `unknown`.
/// Offline the saved session is opened and checked again once online.
class AuthService {
  AuthService({
    required AuthRepository repository,
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required UpdateProfile updateProfile,
    required NetworkMonitor network,
  }) : _repository = repository,
       _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _updateProfile = updateProfile,
       _network = network;

  final AuthRepository _repository;
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final NetworkMonitor _network;
  final StreamController<UserSession> _changes = StreamController.broadcast();

  UserSession _session = const UserSession();
  StreamSubscription<void>? _expiredSubscription;
  StreamSubscription<bool>? _onlineSubscription;
  Future<void>? _restoring;
  bool _revalidating = false;
  bool _restoreFailedOffline = false;

  UserSession get session => _session;

  Stream<UserSession> get changes => _changes.stream;

  /// The server was unreachable at startup and no session is saved on the
  /// device, so the user has to sign in once the connection is back.
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
    _onlineSubscription?.cancel();
    _changes.close();
  }

  Future<void> _restore() async {
    _expiredSubscription = _repository.sessionExpired.listen(
      (_) => _apply(const UserSession.signedOut()),
    );
    _onlineSubscription = _network.onlineChanges
        .where((online) => online)
        .listen((_) => unawaited(_revalidate()));
    try {
      final user = await _repository.restoreSession();
      _apply(
        user == null
            ? const UserSession.signedOut()
            : UserSession.signedIn(user),
      );
    } catch (_) {
      await _restoreOffline();
    }
  }

  /// Opens the session saved on the device; without one the login is needed.
  Future<void> _restoreOffline() async {
    AuthUser? user;
    try {
      user = await _repository.restoreOfflineSession();
    } catch (_) {
      user = null;
    }
    if (user == null) {
      _restoreFailedOffline = true;
      _apply(const UserSession.signedOut());
    } else {
      _apply(UserSession.signedIn(user, isOffline: true));
    }
  }

  /// Confirms an offline session with the server once the network is back.
  Future<void> _revalidate() async {
    if (!_session.isOffline || _revalidating) return;
    _revalidating = true;
    try {
      final user = await _repository.restoreSession();
      _apply(
        user == null
            ? const UserSession.signedOut()
            : UserSession.signedIn(user),
      );
    } catch (_) {
      // Still unreachable: the offline session stays.
    } finally {
      _revalidating = false;
    }
  }

  void _apply(UserSession session) {
    _session = session;
    _changes.add(session);
  }
}
