import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';

void main() {
  group('UserRole.parse', () {
    test('parses known roles from the protocol string', () {
      expect(UserRole.parse('user'), UserRole.user);
      expect(UserRole.parse('user-pro'), UserRole.userPro);
      expect(UserRole.parse('admin'), UserRole.admin);
      expect(UserRole.parse('owner'), UserRole.owner);
    });

    test('an unknown value and null degrade to user', () {
      expect(UserRole.parse('superuser'), UserRole.user);
      expect(UserRole.parse(''), UserRole.user);
      expect(UserRole.parse(null), UserRole.user);
    });

    test('wire matches the protocol string', () {
      expect(UserRole.userPro.wire, 'user-pro');
      expect(UserRole.admin.wire, 'admin');
    });
  });

  group('UserRole permissions', () {
    test('user-pro, admin and owner may create lessons', () {
      expect(UserRole.user.canAuthor, isFalse);
      expect(UserRole.userPro.canAuthor, isTrue);
      expect(UserRole.admin.canAuthor, isTrue);
      expect(UserRole.owner.canAuthor, isTrue);
    });

    test('management belongs to the owner only', () {
      expect(UserRole.owner.canManage, isTrue);
      expect(UserRole.admin.canManage, isFalse);
      expect(UserRole.userPro.canManage, isFalse);
      expect(UserRole.user.canManage, isFalse);
    });
  });

  group('AuthUser.fromJson', () {
    test('reads the profile', () {
      final user = AuthUser.fromJson({
        'id': 'u1',
        'email': 'a@b.c',
        'role': 'user-pro',
        'created_at': '2026-01-01T00:00:00Z',
        'name': 'Andrew',
        'studied_language': 'en',
        'daily_goal_minutes': 15,
      });

      expect(user.role, UserRole.userPro);
      expect(user.name, 'Andrew');
      expect(user.studiedLanguage, 'en');
      expect(user.dailyGoalMinutes, 15);
    });

    test('missing profile fields give null, and so do empty strings', () {
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
