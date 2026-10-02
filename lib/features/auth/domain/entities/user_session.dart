import 'auth_user.dart';

/// What is known about the session right now.
enum AuthStatus {
  /// The stored refresh token hasn't been checked yet.
  unknown,
  authenticated,
  unauthenticated,
}

/// The current session: its status and the signed-in user.
class UserSession {
  const UserSession({
    this.status = AuthStatus.unknown,
    this.user,
    this.isOffline = false,
  });

  const UserSession.signedOut()
    : status = AuthStatus.unauthenticated,
      user = null,
      isOffline = false;

  const UserSession.signedIn(AuthUser this.user, {this.isOffline = false})
    : status = AuthStatus.authenticated;

  final AuthStatus status;
  final AuthUser? user;

  /// Restored from the device without the server; checked again once online.
  final bool isOffline;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isOwner => user?.isOwner ?? false;

  /// Whether the user may create lessons.
  bool get canAuthor => user?.role.canAuthor ?? false;

  /// Whether the user sees the management screen.
  bool get canManage => user?.role.canManage ?? false;
}
