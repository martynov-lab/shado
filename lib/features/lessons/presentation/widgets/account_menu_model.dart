import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';

import '../../../auth/domain/entities/user_session.dart';
import '../../../auth/domain/services/auth_service.dart';

/// The session for the account menu.
class AccountMenuModel extends ElementaryModel {
  AccountMenuModel(ProviderContainer container)
    : _auth = container.read(authServiceProvider);

  final AuthService _auth;

  late final StreamValueNotifier<UserSession> _session = StreamValueNotifier(
    _auth.session,
    _auth.changes,
  );

  ValueListenable<UserSession> get session => _session;

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
