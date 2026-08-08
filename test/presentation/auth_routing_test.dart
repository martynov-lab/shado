import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/app.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/presentation/controllers/auth_providers.dart';
import 'package:shado/features/auth/presentation/pages/login_page.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

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
    String? name,
  }) => login(email: email, password: password);

  @override
  Future<AuthUser?> restoreSession() async {
    restoreCalls++;
    return _current = restored;
  }

  @override
  Future<AuthUser> refreshCurrentUser() async => _current!;

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async => _current!;

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
  Future<List<Topic>> getTopics() async => const [];

  @override
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    required LessonAccent accent,
    required LessonLevel level,
    String? topicId,
    List<int>? boundaries,
    bool? isPublic,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateLesson(Lesson lesson, {bool? isPublic}) async {}

  @override
  Future<void> deleteLesson(String id) async {}

  @override
  Future<void> clearCache() async {}
}

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository auth) async {
    // Телефон: у экрана входа три раскладки, и проверяем ту, что видит
    // большинство.
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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

  /// Экран входа сам по себе, без роутера: так его можно померить на любой
  /// ширине и в любой теме.
  Future<void> pumpLoginPage(
    WidgetTester tester, {
    required Size size,
    required ThemeMode mode,
    bool isRegistration = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: LoginPage(isRegistration: isRegistration),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in const [
    Size(390, 900),
    Size(800, 1200),
    Size(1400, 1000),
  ]) {
    for (final isRegistration in const [false, true]) {
      testWidgets(
        'форма ${isRegistration ? 'регистрации' : 'входа'} '
        'рисуется на ширине ${size.width}',
        (tester) async {
          for (final mode in ThemeMode.values) {
            await pumpLoginPage(
              tester,
              size: size,
              mode: mode,
              isRegistration: isRegistration,
            );

            expect(tester.takeException(), isNull);
            expect(find.byType(AppTextField), findsWidgets);
            expect(
              find.widgetWithText(
                AppButton,
                isRegistration ? 'Создать аккаунт' : 'Войти',
              ),
              findsOneWidget,
            );
          }
        },
      );
    }
  }

  testWidgets('без сессии приложение уводит на вход', (tester) async {
    final auth = FakeAuthRepository();

    await pumpApp(tester, auth);

    expect(find.text('С возвращением'), findsOneWidget);
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
    expect(find.text('С возвращением'), findsNothing);
    // На экране уроков — меню аккаунта в шапке.
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });

  testWidgets('вход по форме открывает главную', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    await tester.enterText(find.byType(AppTextField).first, 'user@example.com');
    await tester.enterText(find.byType(AppTextField).last, 'password123');
    await tester.tap(find.widgetWithText(AppButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });

  testWidgets('короткий пароль форма не пропускает дальше себя', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());

    await tester.enterText(find.byType(AppTextField).first, 'user@example.com');
    await tester.enterText(find.byType(AppTextField).last, 'short');
    await tester.tap(find.widgetWithText(AppButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Не короче 8 символов'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsNothing);
  });

  testWidgets('пароль показывается по нажатию на глаз', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).last);

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byType(AppFieldSuffixButton));
    await tester.pumpAndSettle();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('без согласия с условиями регистрация не отправляется', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());

    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(find.text('Создать аккаунт'), findsWidgets);

    await tester.tap(find.byType(AppCheckbox));
    await tester.pumpAndSettle();

    final submit = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Создать аккаунт'),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('в меню аккаунта обычному пользователю нет разделов владельца', (
    tester,
  ) async {
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

    // «Управление» и «Пользователи» — разделы владельца, их видит только owner.
    expect(find.text('Управление'), findsNothing);
    expect(find.text('Пользователи'), findsNothing);
  });

  testWidgets('владельцу в меню аккаунта видны «Управление» и «Пользователи»', (
    tester,
  ) async {
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

    expect(find.text('Управление'), findsOneWidget);
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

    expect(find.text('С возвращением'), findsOneWidget);
  });
}
