import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/core/storage/token_storage.dart';
import 'package:shado/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:shado/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shado/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';

import '../core/fake_http_adapter.dart';

/// A server that signs anyone in as [_user]; `/v1/me` fails with [meError].
class _FakeAuthRemote implements AuthRemoteDataSource {
  _FakeAuthRemote({this.meError});

  final Object? meError;

  @override
  Future<AuthUser> me() async {
    if (meError != null) throw meError!;
    return _user;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(user: _user, tokens: _tokens);

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> logout(String refreshToken) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// The device user storage in memory.
class _FakeAuthLocal implements AuthLocalDataSource {
  AuthUser? user;

  @override
  Future<AuthUser?> readUser() async => user;

  @override
  Future<void> saveUser(AuthUser user) async => this.user = user;

  @override
  Future<void> clear() async => user = null;
}

void main() {
  group('$AuthRepositoryImpl offline session', () {
    test('sign-in keeps the user on the device', () async {
      final local = _FakeAuthLocal();
      final repository = _makeRepository(local: local);

      await repository.login(email: 'user@example.com', password: 'secret12');

      expect(local.user, equals(_user));
    });

    test(
      'restoreOfflineSession returns the saved user with a refresh token',
      () async {
        final repository = _makeRepository(
          local: _FakeAuthLocal()..user = _user,
          tokens: FakeTokenStorage(refresh: 'refresh-1'),
        );

        expect(await repository.restoreOfflineSession(), equals(_user));
        expect(repository.currentUser, equals(_user));
      },
    );

    test(
      'restoreOfflineSession returns null without a refresh token',
      () async {
        final repository = _makeRepository(
          local: _FakeAuthLocal()..user = _user,
        );

        expect(await repository.restoreOfflineSession(), isNull);
      },
    );

    test('a server failure on restore keeps the session', () async {
      final local = _FakeAuthLocal()..user = _user;
      final tokens = FakeTokenStorage(refresh: 'refresh-1');
      final repository = _makeRepository(
        local: local,
        tokens: tokens,
        meError: const ApiException(
          code: ApiErrorCode.unknown,
          message: 'bad gateway',
          status: 502,
        ),
      );

      await expectLater(
        repository.restoreSession(),
        throwsA(isA<ApiException>()),
      );
      expect(tokens.cleared, isFalse);
      expect(local.user, equals(_user));
    });

    test('a rejected session on restore is forgotten', () async {
      final local = _FakeAuthLocal()..user = _user;
      final repository = _makeRepository(
        local: local,
        tokens: FakeTokenStorage(refresh: 'refresh-1'),
        meError: const ApiException(
          code: ApiErrorCode.unauthorized,
          message: 'unauthorized',
          status: 401,
        ),
      );

      expect(await repository.restoreSession(), isNull);
      expect(local.user, isNull);
    });

    test('sign-out forgets the saved user', () async {
      final local = _FakeAuthLocal()..user = _user;
      final repository = _makeRepository(
        local: local,
        tokens: FakeTokenStorage(refresh: 'refresh-1'),
      );

      await repository.logout();

      expect(local.user, isNull);
    });
  });

  group('$AuthUser', () {
    test('toJson is read back by fromJson', () {
      final user = AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.userPro,
        createdAt: DateTime.utc(2026, 3, 4),
        name: 'Ann',
        studiedLanguage: 'fr',
        dailyGoalMinutes: 20,
      );

      final restored = AuthUser.fromJson(user.toJson());

      expect(restored, equals(user));
      expect(restored.createdAt, equals(user.createdAt));
    });
  });
}

final _user = AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  role: UserRole.user,
  createdAt: DateTime.utc(2026),
);

const _tokens = AuthTokens(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  expiresIn: 900,
);

AuthRepositoryImpl _makeRepository({
  required AuthLocalDataSource local,
  TokenStorage? tokens,
  Object? meError,
}) {
  final repository = AuthRepositoryImpl(
    remote: _FakeAuthRemote(meError: meError),
    local: local,
    tokens: tokens ?? FakeTokenStorage(),
    // Cache cleanup does not matter here.
    // ignore: no-empty-block
    onSignedOut: () async {},
  );
  addTearDown(repository.dispose);
  return repository;
}
