import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_providers.dart';

/// Что известно о сессии прямо сейчас.
enum AuthStatus {
  /// Ещё выясняем: на старте пробуем поднять сессию по refresh-токену.
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

  /// Идёт запрос: форма заблокирована.
  final bool isBusy;

  /// Что показать пользователю; `null` — показывать нечего.
  final String? error;

  /// До какого момента `/v1/auth/*` отвечает `429`. Форма до него заперта.
  final DateTime? retryAt;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isOwner => user?.isOwner ?? false;

  /// Сколько ещё ждать после превышения лимита попыток.
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

/// Вход, регистрация, выход и восстановление сессии на старте.
class AuthController extends Notifier<AuthState> {
  /// Сколько держать форму запертой после `429`. Сервер считает попытки
  /// поминутно, поэтому минуты и хватает.
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
    // Состояние на старте — `unknown`: пока refresh не проверен, роутер держит
    // заставку и не бросает пользователя на экран входа.
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
      // Сервер недоступен — это не повод стирать сессию: refresh на месте, и
      // следующая попытка может пройти.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Нет связи с сервером — войдите, когда сеть появится',
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn({required String email, required String password}) {
    return _submit(() => ref.read(signInProvider)(
      email: email,
      password: password,
    ));
  }

  Future<bool> signUp({required String email, required String password}) {
    return _submit(() => ref.read(signUpProvider)(
      email: email,
      password: password,
    ));
  }

  /// Общая обвязка входа и регистрации: блокировка формы, разбор ошибок,
  /// таймер после превышения лимита попыток.
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

  /// Перечитывает `/v1/me`: роль могли изменить в админке, и она меняется
  /// раньше, чем истечёт access-токен.
  Future<void> reloadUser() async {
    try {
      final user = await ref.read(getCurrentUserProvider)();
      state = state.copyWith(user: user);
    } catch (_) {
      // Не выходить же из-за неудачной проверки роли.
    }
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

  /// Сообщение для формы. «Нет такого email» и «неверный пароль» намеренно
  /// неразличимы: подсказывать, какие адреса зарегистрированы, незачем.
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
