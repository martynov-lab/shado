import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/core/network/network_status.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';

import '../../../../auth/domain/services/auth_service.dart';

/// What the app shell needs from the session and the connection.
class MainShellModel extends ElementaryModel {
  MainShellModel(ProviderContainer container)
    : _auth = container.read(authServiceProvider),
      _network = container.read(networkStatusProvider);

  final AuthService _auth;
  final NetworkStatus _network;

  late final StreamValueNotifier<bool> _canAuthor = StreamValueNotifier(
    _auth.session.canAuthor,
    _auth.changes.map((session) => session.canAuthor),
  );
  late final StreamValueNotifier<String> _email = StreamValueNotifier(
    _auth.session.user?.email ?? '',
    _auth.changes.map((session) => session.user?.email ?? ''),
  );

  late final StreamValueNotifier<bool> _isOnline = StreamValueNotifier(
    _network.isOnline,
    _network.changes,
  );

  ValueListenable<bool> get canAuthor => _canAuthor;

  ValueListenable<bool> get isOnline => _isOnline;
  ValueListenable<String> get email => _email;

  /// The role may have been changed by the owner since the last start.
  Future<void> reloadUser() => _auth.reloadUser();

  @override
  void dispose() {
    _canAuthor.dispose();
    _email.dispose();
    _isOnline.dispose();
    super.dispose();
  }
}
