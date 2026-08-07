import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';

void main() {
  group('UserRole.parse', () {
    test('разбирает известные роли по строке протокола', () {
      expect(UserRole.parse('user'), UserRole.user);
      expect(UserRole.parse('user-pro'), UserRole.userPro);
      expect(UserRole.parse('admin'), UserRole.admin);
      expect(UserRole.parse('owner'), UserRole.owner);
    });

    test('незнакомое значение и null деградируют к user', () {
      expect(UserRole.parse('superuser'), UserRole.user);
      expect(UserRole.parse(''), UserRole.user);
      expect(UserRole.parse(null), UserRole.user);
    });

    test('wire совпадает со строкой протокола', () {
      expect(UserRole.userPro.wire, 'user-pro');
      expect(UserRole.admin.wire, 'admin');
    });
  });

  group('UserRole права', () {
    test('создавать уроки могут user-pro, admin и owner', () {
      expect(UserRole.user.canAuthor, isFalse);
      expect(UserRole.userPro.canAuthor, isTrue);
      expect(UserRole.admin.canAuthor, isTrue);
      expect(UserRole.owner.canAuthor, isTrue);
    });

    test('управление — только у owner', () {
      expect(UserRole.owner.canManage, isTrue);
      expect(UserRole.admin.canManage, isFalse);
      expect(UserRole.userPro.canManage, isFalse);
      expect(UserRole.user.canManage, isFalse);
    });
  });

  group('AuthUser.fromJson', () {
    test('читает профиль', () {
      final user = AuthUser.fromJson({
        'id': 'u1',
        'email': 'a@b.c',
        'role': 'user-pro',
        'created_at': '2026-01-01T00:00:00Z',
        'name': 'Андрей',
        'studied_language': 'en',
        'daily_goal_minutes': 15,
      });

      expect(user.role, UserRole.userPro);
      expect(user.name, 'Андрей');
      expect(user.studiedLanguage, 'en');
      expect(user.dailyGoalMinutes, 15);
    });

    test('отсутствие полей профиля даёт null, пустые строки тоже', () {
      final user = AuthUser.fromJson({
        'id': 'u1',
        'email': 'a@b.c',
        'role': 'user',
        'created_at': '2026-01-01T00:00:00Z',
        'name': '  ',
      });

      expect(user.name, isNull);
      expect(user.studiedLanguage, isNull);
      expect(user.dailyGoalMinutes, isNull);
    });
  });
}
