import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Пара токенов, как её отдаёт `/v1/auth/*`.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
  );

  final String accessToken;
  final String refreshToken;

  /// Сколько секунд живёт access. Держим для диагностики: обновление идёт не по
  /// таймеру, а по ответу 401.
  final int expiresIn;
}

/// Хранилище токенов.
///
/// Refresh переживает перезапуск и лежит в защищённом хранилище платформы,
/// access живёт 15 минут и хранится только в памяти — писать его на диск
/// незачем.
abstract interface class TokenStorage {
  /// Текущий access; `null` — его ещё не получали или сессию закрыли.
  String? get accessToken;

  Future<String?> readRefreshToken();

  Future<void> save(AuthTokens tokens);

  /// Забывает обе половины сессии.
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _refreshKey = 'shado.refresh_token';

  final FlutterSecureStorage _storage;

  String? _accessToken;

  /// Прочитанный с диска refresh: на старте его спрашивают дважды подряд
  /// (восстановление сессии и первый запрос), а обращение к keychain не
  /// бесплатное.
  String? _refreshToken;
  bool _refreshLoaded = false;

  @override
  String? get accessToken => _accessToken;

  @override
  Future<String?> readRefreshToken() async {
    if (_refreshLoaded) return _refreshToken;
    _refreshToken = await _storage.read(key: _refreshKey);
    _refreshLoaded = true;
    return _refreshToken;
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _refreshLoaded = true;
    // Сервер ротирует refresh при каждом обновлении: старый после этого
    // недействителен, поэтому новый пишем сразу.
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _refreshLoaded = true;
    await _storage.delete(key: _refreshKey);
  }
}
