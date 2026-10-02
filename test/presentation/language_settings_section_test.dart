import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/languages/domain/entities/language.dart';
import 'package:shado/features/settings/presentation/screens/settings_page.dart';
import 'package:shado/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_language_repository.dart';

/// The language block of the settings screen.
void main() {
  const english = Language(
    code: 'en',
    name: 'English',
    accents: [Accent(code: 'US', name: 'American', isDefault: true)],
  );
  const french = Language(code: 'fr', name: 'French');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSettings(
    WidgetTester tester,
    UserRole role, {
    Object? profileError,
  }) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: testUser(role: role),
              profileError: profileError,
            ),
          ),
          languageRepositoryProvider.overrideWithValue(
            const FakeLanguageRepository([english, french]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the owner sees the voice-over voice picker', (tester) async {
    await pumpSettings(tester, UserRole.owner);

    expect(find.text('Studied language'), findsOneWidget);
    expect(find.text('AI voiceover voice'), findsOneWidget);
    // Nothing is picked yet, so the server decides.
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('a plain user does not see the voice-over voice', (tester) async {
    await pumpSettings(tester, UserRole.user);

    expect(find.text('Studied language'), findsOneWidget);
    expect(find.text('AI voiceover voice'), findsNothing);
  });

  testWidgets('a language rejected by the server is reported', (tester) async {
    await pumpSettings(
      tester,
      UserRole.user,
      profileError: const ApiException(
        code: ApiErrorCode.validationError,
        message: 'unknown language',
        status: 422,
      ),
    );

    await tester.tap(find.text('Studied language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(
      find.text('The server did not accept the language — choose another one'),
      findsOneWidget,
    );
  });
}
