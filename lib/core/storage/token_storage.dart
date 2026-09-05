import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token pair as returned by `/v1/auth/*`.
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

  /// Access token lifetime in seconds.
  final int expiresIn;
}

/// Token storage: refresh on disk, access in memory only.
abstract interface class TokenStorage {
  /// Current access token; `null` when there is no session.
  String? get accessToken;

  Future<String?> readRefreshToken();

  Future<void> save(AuthTokens tokens);

  /// Forgets both tokens.
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _refreshKey = 'shado.refresh_token';

  final FlutterSecureStorage _storage;

  String? _accessToken;

  /// Cached refresh token — keychain reads are not free.
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
    // The server rotates the refresh token on every refresh — store it now.
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
