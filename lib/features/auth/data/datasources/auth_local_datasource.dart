import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_user.dart';

/// The last signed-in user kept on the device for offline starts.
abstract interface class AuthLocalDataSource {
  /// `null` when nothing is saved or the saved value is unreadable.
  Future<AuthUser?> readUser();

  Future<void> saveUser(AuthUser user);

  Future<void> clear();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  SecureAuthLocalDataSource({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _userKey = 'shado.user';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveUser(AuthUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _userKey);
}
