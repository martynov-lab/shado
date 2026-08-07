import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_permissions.dart';

Lesson _lesson({required bool isPublic}) => Lesson(
  id: 'l1',
  title: 'Урок',
  audioPath: 'a',
  durationMs: 1000,
  createdAt: DateTime.utc(2026),
  segments: const [Segment(index: 0, text: 'x', startMs: 0, endMs: 1000)],
  isPublic: isPublic,
);

void main() {
  group('canCreateLessons', () {
    test('доступно авторам, недоступно обычному user и без роли', () {
      expect(canCreateLessons(UserRole.user), isFalse);
      expect(canCreateLessons(UserRole.userPro), isTrue);
      expect(canCreateLessons(UserRole.admin), isTrue);
      expect(canCreateLessons(UserRole.owner), isTrue);
      expect(canCreateLessons(null), isFalse);
    });
  });

  group('canModifyLesson', () {
    final public = _lesson(isPublic: true);
    final private = _lesson(isPublic: false);

    test('публичный урок правят только admin и owner', () {
      expect(canModifyLesson(UserRole.owner, public), isTrue);
      expect(canModifyLesson(UserRole.admin, public), isTrue);
      expect(canModifyLesson(UserRole.userPro, public), isFalse);
      expect(canModifyLesson(UserRole.user, public), isFalse);
    });

    test('видимый приватный урок — мой: правит любой автор', () {
      expect(canModifyLesson(UserRole.userPro, private), isTrue);
      expect(canModifyLesson(UserRole.admin, private), isTrue);
      expect(canModifyLesson(UserRole.owner, private), isTrue);
      expect(canModifyLesson(UserRole.user, private), isFalse);
    });

    test('без роли ничего править нельзя', () {
      expect(canModifyLesson(null, public), isFalse);
      expect(canModifyLesson(null, private), isFalse);
    });
  });
}
