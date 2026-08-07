import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_user.dart';

/// Ответ `/v1/auth/register` и `/v1/auth/login`: пользователь плюс пара токенов.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    tokens: AuthTokens.fromJson(json),
  );

  final AuthUser user;
  final AuthTokens tokens;
}

/// `/v1/auth/*` и `/v1/me`.
abstract interface class AuthRemoteDataSource {
  /// [name] необязательно: пустое имя не отправляем.
  Future<AuthSession> register({
    required String email,
    required String password,
    String? name,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<AuthTokens> refresh(String refreshToken);

  Future<AuthUser> me();

  /// Правит профиль (`PATCH /v1/me`). Шлём только переданные поля: `null` —
  /// поле не трогаем.
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  });

  Future<void> logout(String refreshToken);
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource(this._client);

  /// Запросам авторизации `Authorization` не нужен, а на старте его ещё и нет.
  static final Options _anonymous = Options(
    extra: {AuthInterceptor.skipAuthKey: true},
  );

  final ApiClient _client;

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final trimmedName = name?.trim();
    final response = await _client.post(
      '/v1/auth/register',
      data: {
        'email': email,
        'password': password,
        // Пустое имя не отправляем — необязательное поле.
        'name': ?(trimmedName == null || trimmedName.isEmpty
            ? null
            : trimmedName),
      },
      options: _anonymous,
    );
    return AuthSession.fromJson(response.data!);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/v1/auth/login',
      data: {'email': email, 'password': password},
      options: _anonymous,
    );
    return AuthSession.fromJson(response.data!);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _client.post(
      '/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: _anonymous,
    );
    return AuthTokens.fromJson(response.data!);
  }

  @override
  Future<AuthUser> me() async {
    final json = await _client.get('/v1/me');
    return AuthUser.fromJson(json);
  }

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    final response = await _client.patch(
      '/v1/me',
      data: {
        'name': ?name,
        'studied_language': ?studiedLanguage,
        'daily_goal_minutes': ?dailyGoalMinutes,
      },
    );
    return AuthUser.fromJson(response.data!);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _client.post(
      '/v1/auth/logout',
      data: {'refresh_token': refreshToken},
      options: _anonymous,
    );
  }
}
