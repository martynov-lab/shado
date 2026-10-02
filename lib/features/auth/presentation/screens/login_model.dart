import 'package:elementary/elementary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/auth_providers.dart';

import '../../domain/services/auth_service.dart';

/// Sign-in and sign-up on top of the session service.
class LoginModel extends ElementaryModel {
  LoginModel(ProviderContainer container)
    : _auth = container.read(authServiceProvider);

  final AuthService _auth;

  /// The server was unreachable when the app started.
  bool get restoreFailedOffline => _auth.restoreFailedOffline;

  Future<void> signIn({required String email, required String password}) =>
      _auth.signIn(email: email, password: password);

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) => _auth.signUp(email: email, password: password, name: name);
}
