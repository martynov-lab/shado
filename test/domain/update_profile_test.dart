import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';

/// A repository that only records the `updateProfile` arguments.
class _FakeAuthRepository implements AuthRepository {
  ({String? name, String? studiedLanguage, int? dailyGoalMinutes})? lastCall;

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    lastCall = (
      name: name,
      studiedLanguage: studiedLanguage,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    return AuthUser(
      id: 'u1',
      email: 'a@b.c',
      role: UserRole.user,
      createdAt: DateTime.utc(2026),
      name: name,
      studiedLanguage: studiedLanguage,
      dailyGoalMinutes: dailyGoalMinutes,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('UpdateProfile', () {
    test('a name that is too long is rejected before the network', () {
      final repo = _FakeAuthRepository();
      final usecase = UpdateProfile(repo);

      // Validation throws synchronously, before the repository is touched.
      expect(
        () => usecase(name: 'a' * (kMaxNameLength + 1)),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.lastCall, isNull);
    });

    test('a goal outside 0..1440 is rejected', () {
      final repo = _FakeAuthRepository();
      final usecase = UpdateProfile(repo);

      expect(
        () => usecase(dailyGoalMinutes: -1),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => usecase(dailyGoalMinutes: kMaxDailyGoalMinutes + 1),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.lastCall, isNull);
    });

    test('valid fields reach the repository with the name trimmed', () async {
      final repo = _FakeAuthRepository();
      final usecase = UpdateProfile(repo);

      await usecase(name: '  Andrew  ', studiedLanguage: 'en', dailyGoalMinutes: 15);

      expect(repo.lastCall?.name, 'Andrew');
      expect(repo.lastCall?.studiedLanguage, 'en');
      expect(repo.lastCall?.dailyGoalMinutes, 15);
    });
  });
}
