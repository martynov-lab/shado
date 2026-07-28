import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/app.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/presentation/controllers/auth_providers.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';

/// Сессия без сети: тест управляет тем, что вернёт восстановление.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restored});

  /// Кого «вспомнит» приложение на старте; `null` — сессии нет.
  final AuthUser? restored;

  final _expired = StreamController<void>.broadcast();

  AuthUser? _current;
  int restoreCalls = 0;

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    return _current = AuthUser(
      id: 'user-1',
      email: email,
      role: UserRole.user,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) => login(email: email, password: password);

  @override
  Future<AuthUser?> restoreSession() async {
    restoreCalls++;
    return _current = restored;
  }

  @override
  Future<AuthUser> refreshCurrentUser() async => _current!;

  @override
  Future<void> logout() async => _current = null;
}

/// Уроков нет: экраны списка нас здесь не интересуют.
class FakeLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> getLessons() async => const [];

  @override
  Future<void> syncLessons() async {}

  @override
  Future<Lesson?> getLesson(String id) async => null;

  @override
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  }) async => const AudioUpload(audioId: 'a', durationMs: 1, sizeBytes: 1);

  @override
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    List<int>? boundaries,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateLesson(Lesson lesson) async {}

  @override
  Future<void> deleteLesson(String id) async {}

  @override
  Future<void> clearCache() async {}
}

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository auth) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          lessonRepositoryProvider.overrideWithValue(FakeLessonRepository()),
        ],
        child: const ShadoApp(),
      ),
    );
    // Первый кадр — заставка, пока проверяется refresh-токен.
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('без сессии приложение уводит на вход', (tester) async {
    final auth = FakeAuthRepository();

    await pumpApp(tester, auth);

    expect(find.text('Вход в Shado'), findsOneWidget);
    expect(auth.restoreCalls, 1);
  });

  testWidgets('сохранённый refresh поднимает сессию сам', (tester) async {
    final auth = FakeAuthRepository(
      restored: AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.user,
        createdAt: DateTime.utc(2026),
      ),
    );

    await pumpApp(tester, auth);

    // Экрана входа пользователь даже не увидел.
    expect(find.text('Вход в Shado'), findsNothing);
    expect(find.widgetWithText(AppBar, 'Главная'), findsOneWidget);
  });

  testWidgets('вход по форме открывает главную', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Главная'), findsOneWidget);
  });

  testWidgets('короткий пароль форма не пропускает дальше себя', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Не короче 8 символов'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Главная'), findsNothing);
  });

  testWidgets('раздел с пользователями виден только владельцу', (tester) async {
    final auth = FakeAuthRepository(
      restored: AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.user,
        createdAt: DateTime.utc(2026),
      ),
    );
    await pumpApp(tester, auth);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Пользователи'), findsNothing);
    expect(find.text('Выйти'), findsOneWidget);
  });

  testWidgets('владельцу раздел с пользователями показывается', (tester) async {
    final auth = FakeAuthRepository(
      restored: AuthUser(
        id: 'owner-1',
        email: 'arovitm@gmail.com',
        role: UserRole.owner,
        createdAt: DateTime.utc(2026),
      ),
    );
    await pumpApp(tester, auth);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Пользователи'), findsOneWidget);
  });

  testWidgets('выход возвращает на экран входа', (tester) async {
    final auth = FakeAuthRepository(
      restored: AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.user,
        createdAt: DateTime.utc(2026),
      ),
    );
    await pumpApp(tester, auth);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('Вход в Shado'), findsOneWidget);
  });
}
