import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';

/// Network status driven by the test.
class _FakeNetworkMonitor implements NetworkMonitor {
  final StreamController<bool> changes = StreamController.broadcast();

  @override
  Stream<bool> get onlineChanges => changes.stream;

  @override
  Future<bool> isOnline() async => true;
}

/// A server that is unreachable until [reachable] is set.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.saved, this.onServer});

  /// The user kept on the device.
  final AuthUser? saved;

  /// What the server returns once reachable; `null` rejects the session.
  final AuthUser? onServer;

  bool reachable = false;

  /// Thrown by `restoreSession` while the server is not [reachable].
  Object failure = const NetworkFailure('offline');

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  Future<AuthUser?> restoreSession() async {
    if (!reachable) throw failure;
    return onServer;
  }

  @override
  Future<AuthUser?> restoreOfflineSession() async => saved;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('$AuthService offline', () {
    test(
      'restore opens the saved session when the server is unreachable',
      () async {
        final service = _makeService(_FakeAuthRepository(saved: _user));

        await service.restore();

        expect(service.session.isAuthenticated, isTrue);
        expect(service.session.isOffline, isTrue);
        expect(service.session.user, equals(_user));
        expect(service.restoreFailedOffline, isFalse);
      },
    );

    test('a server failure at start opens the saved session', () async {
      final repository = _FakeAuthRepository(saved: _user)
        ..failure = StateError('bad gateway');
      final service = _makeService(repository);

      await service.restore();

      expect(service.session.isAuthenticated, isTrue);
      expect(service.session.isOffline, isTrue);
    });

    test('restore signs out offline when nothing is saved', () async {
      final service = _makeService(_FakeAuthRepository());

      await service.restore();

      expect(service.session.isAuthenticated, isFalse);
      expect(service.restoreFailedOffline, isTrue);
    });

    test('the session goes online when the network is back', () async {
      final repository = _FakeAuthRepository(saved: _user, onServer: _user);
      final network = _FakeNetworkMonitor();
      final service = _makeService(repository, network: network);
      await service.restore();

      repository.reachable = true;
      network.changes.add(true);
      await pumpEventQueue();

      expect(service.session.isAuthenticated, isTrue);
      expect(service.session.isOffline, isFalse);
    });

    test(
      'the session ends when the server rejects it after reconnect',
      () async {
        final repository = _FakeAuthRepository(saved: _user);
        final network = _FakeNetworkMonitor();
        final service = _makeService(repository, network: network);
        await service.restore();

        repository.reachable = true;
        network.changes.add(true);
        await pumpEventQueue();

        expect(service.session.isAuthenticated, isFalse);
      },
    );

    test(
      'the offline session stays when the server is still unreachable',
      () async {
        final network = _FakeNetworkMonitor();
        final service = _makeService(
          _FakeAuthRepository(saved: _user),
          network: network,
        );
        await service.restore();

        network.changes.add(true);
        await pumpEventQueue();

        expect(service.session.isAuthenticated, isTrue);
        expect(service.session.isOffline, isTrue);
      },
    );
  });
}

final _user = AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  role: UserRole.user,
  createdAt: DateTime.utc(2026),
  studiedLanguage: 'en',
);

AuthService _makeService(AuthRepository repository, {NetworkMonitor? network}) {
  final service = AuthService(
    repository: repository,
    signIn: SignIn(repository),
    signUp: SignUp(repository),
    signOut: SignOut(repository),
    getCurrentUser: GetCurrentUser(repository),
    updateProfile: UpdateProfile(repository),
    network: network ?? _FakeNetworkMonitor(),
  );
  addTearDown(service.dispose);
  return service;
}
