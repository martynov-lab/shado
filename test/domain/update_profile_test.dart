import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';

/// Репозиторий, который лишь записывает аргументы `updateProfile`.
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
    test('слишком длинное имя отвергается до сети', () {
      final repo = _FakeAuthRepository();
      final usecase = UpdateProfile(repo);

      // Валидация бросает синхронно — до обращения к репозиторию.
      expect(
        () => usecase(name: 'a' * (kMaxNameLength + 1)),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.lastCall, isNull);
    });

    test('цель вне диапазона 0..1440 отвергается', () {
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

    test('корректные поля уходят в репозиторий с обрезанным именем', () async {
      final repo = _FakeAuthRepository();
      final usecase = UpdateProfile(repo);

      await usecase(name: '  Андрей  ', studiedLanguage: 'en', dailyGoalMinutes: 15);

      expect(repo.lastCall?.name, 'Андрей');
      expect(repo.lastCall?.studiedLanguage, 'en');
      expect(repo.lastCall?.dailyGoalMinutes, 15);
    });
  });
}
