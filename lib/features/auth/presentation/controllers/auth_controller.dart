import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_providers.dart';

/// What is known about the session right now.
enum AuthStatus {
  /// The session is still being checked against the refresh token.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isBusy = false,
    this.error,
    this.retryAt,
  });

  final AuthStatus status;
  final AuthUser? user;

  /// A request is running — the form is blocked.
  final bool isBusy;

  /// Error message for the form.
  final String? error;

  /// Until when the form stays locked after a `429`.
  final DateTime? retryAt;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isOwner => user?.isOwner ?? false;

  /// Whether the user may create lessons.
  bool get canAuthor => user?.role.canAuthor ?? false;

  /// Whether the user sees the management tab.
  bool get canManage => user?.role.canManage ?? false;

  /// How long to wait after the attempt limit is hit.
  Duration get retryIn {
    final until = retryAt;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isRateLimited => retryIn > Duration.zero;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool clearUser = false,
    bool? isBusy,
    String? error,
    bool clearError = false,
    DateTime? retryAt,
    bool clearRetryAt = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      retryAt: clearRetryAt ? null : (retryAt ?? this.retryAt),
    );
  }
}

/// Sign-in, sign-up, sign-out and session restore at startup.
class AuthController extends Notifier<AuthState> {
  /// How long the form stays locked after a `429`.
  static const Duration _rateLimitCooldown = Duration(minutes: 1);

  @override
  AuthState build() {
    final subscription = ref
        .watch(authRepositoryProvider)
        .sessionExpired
        .listen((_) {
          state = const AuthState(status: AuthStatus.unauthenticated);
        });
    ref.onDispose(subscription.cancel);
    // Start as `unknown`: the router keeps the splash until refresh is checked.
    unawaited(_restore());
    return const AuthState();
  }

  Future<void> _restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).restoreSession();
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } on NetworkFailure {
      // The server is down — keep the session, the refresh token stays.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Нет связи с сервером — войдите, когда сеть появится',
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn({required String email, required String password}) {
    return _submit(
      () => ref.read(signInProvider)(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return _submit(
      () => ref.read(signUpProvider)(
        email: email,
        password: password,
        name: name,
      ),
    );
  }

  /// Sign-in and sign-up plumbing: form locking, error parsing, attempt
  /// limits.
  Future<bool> _submit(Future<AuthUser> Function() action) async {
    if (state.isBusy || state.isRateLimited) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(
        isBusy: false,
        error: _messageFor(error),
        retryAt: error.code == ApiErrorCode.rateLimited
            ? DateTime.now().add(_rateLimitCooldown)
            : null,
      );
      return false;
    } on Failure catch (failure) {
      state = state.copyWith(isBusy: false, error: failure.message);
      return false;
    }
  }

  /// Re-reads `/v1/me` — the role could have changed in the admin panel.
  Future<void> reloadUser() async {
    try {
      final user = await ref.read(getCurrentUserProvider)();
      state = state.copyWith(user: user);
    } catch (_) {
      // A failed role check does not break the session.
    }
  }

  /// Updates the profile; errors bubble up to the settings screen.
  Future<void> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    final updated = await ref.read(updateProfileProvider)(
      name: name,
      studiedLanguage: studiedLanguage,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    state = state.copyWith(user: updated);
  }

  Future<void> signOut() async {
    state = state.copyWith(isBusy: true);
    try {
      await ref.read(signOutProvider)();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Error message for the form.
  String _messageFor(ApiException error) => switch (error.code) {
    ApiErrorCode.invalidCredentials => 'Неверный email или пароль',
    ApiErrorCode.emailTaken =>
      'Такой email уже зарегистрирован — попробуйте войти',
    ApiErrorCode.rateLimited => 'Слишком много попыток. Подождите минуту',
    _ => error.message,
  };
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
