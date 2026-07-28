import 'dart:async';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Сессия поверх API и защищённого хранилища.
///
/// Всё, что нужно стереть при выходе кроме токенов (кеш уроков и скачанное
/// аудио), убирает [onSignedOut]: репозиторию авторизации незачем знать про
/// уроки.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokens,
    required Future<void> Function() onSignedOut,
  }) : _remote = remote,
       _tokens = tokens,
       _onSignedOut = onSignedOut;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final Future<void> Function() _onSignedOut;

  final StreamController<void> _expired = StreamController<void>.broadcast();

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    final session = await _remote.register(
      email: normalizeEmail(email),
      password: password,
    );
    await _tokens.save(session.tokens);
    return _currentUser = session.user;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _remote.login(
      email: normalizeEmail(email),
      password: password,
    );
    await _tokens.save(session.tokens);
    return _currentUser = session.user;
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null) return null;
    try {
      final tokens = await _remote.refresh(refresh);
      await _tokens.save(tokens);
      return _currentUser = await _remote.me();
    } on ApiException {
      // Сервер отверг токен — сессии больше нет. Сетевой сбой сюда не попадает
      // и оставляет возможность попробовать позже.
      await _forget();
      return null;
    }
  }

  @override
  Future<AuthUser> refreshCurrentUser() async {
    return _currentUser = await _remote.me();
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh != null) {
      try {
        await _remote.logout(refresh);
      } catch (_) {
        // Ответ всегда 204, но и его потеря не должна мешать выйти локально.
      }
    }
    await _forget();
  }

  /// Вызывается сетевым слоем, когда refresh отвергнут: сессия кончилась не по
  /// воле пользователя.
  Future<void> handleSessionExpired() async {
    await _forget();
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> _forget() async {
    _currentUser = null;
    await _tokens.clear();
    await _onSignedOut();
  }

  void dispose() => _expired.close();

  /// Сервер и так приводит почту к нижнему регистру, но делаем это и здесь:
  /// иначе «Вход» и «Регистрация» поведут себя по-разному при опечатке в
  /// регистре.
  static String normalizeEmail(String email) => email.trim().toLowerCase();
}
