import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shado/features/languages/domain/entities/language.dart';
import 'package:shado/features/languages/presentation/controllers/language_providers.dart';
import 'package:shado/features/settings/presentation/widgets/language_settings_section.dart';
import 'package:shado/theme/theme.dart';

/// A session with the given role and the English profile.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.role);

  final UserRole role;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 'user-1',
      email: 'user@example.com',
      role: role,
      createdAt: DateTime.utc(2026),
      studiedLanguage: 'en',
    ),
  );
}

/// The voice-over voice is an owner-only setting inside the language block.
void main() {
  const english = Language(
    code: 'en',
    name: 'Английский',
    accents: [Accent(code: 'US', name: 'Американский', isDefault: true)],
  );

  Future<void> pumpSection(WidgetTester tester, UserRole role) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuthController(role)),
          languagesProvider.overrideWith((ref) async => [english]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: LanguageSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('владелец видит выбор голоса озвучки', (tester) async {
    await pumpSection(tester, UserRole.owner);

    expect(find.text('Изучаемый язык'), findsOneWidget);
    expect(find.text('Голос озвучки ИИ'), findsOneWidget);
    // Nothing is picked yet, so the server decides.
    expect(find.text('По умолчанию'), findsOneWidget);
  });

  testWidgets('обычный пользователь голос озвучки не видит', (tester) async {
    await pumpSection(tester, UserRole.user);

    expect(find.text('Изучаемый язык'), findsOneWidget);
    expect(find.text('Голос озвучки ИИ'), findsNothing);
  });
}
