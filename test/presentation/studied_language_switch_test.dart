import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/library_providers.dart';
import 'package:shado/features/lessons/domain/entities/library_root.dart';
import 'package:shado/features/lessons/domain/repositories/library_repository.dart';
import 'package:shado/features/settings/presentation/screens/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_lesson_repository.dart';

/// CLIENT_LANGUAGES_PLAN §3.4: the order of a language switch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<
    ({
      ProviderContainer container,
      SettingsModel model,
      FakeAuthRepository auth,
      FakeLessonRepository lessons,
    })
  >
  build({Object? profileError}) async {
    final auth = FakeAuthRepository(
      user: testUser(),
      profileError: profileError,
    );
    final lessons = FakeLessonRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        lessonRepositoryProvider.overrideWithValue(lessons),
        libraryRepositoryProvider.overrideWithValue(_EmptyLibrary()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authServiceProvider).restore();
    final model = SettingsModel(container);
    addTearDown(model.dispose);
    return (container: container, model: model, auth: auth, lessons: lessons);
  }

  /// Counts catalog resets: the lessons screen drops its filters on each.
  List<void> listenResets(ProviderContainer container) {
    final resets = <void>[];
    container.read(lessonCatalogServiceProvider).resets.listen(resets.add);
    return resets;
  }

  test('a successful switch wipes the cache and resets the catalog', () async {
    final env = await build();
    final resets = listenResets(env.container);

    await env.model.changeStudiedLanguage('fr');
    await pumpEventQueue();

    expect(env.auth.savedLanguages, equals(['fr']));
    expect(env.lessons.cleared, isTrue);
    // An accent of the previous language would give a `422` on the catalog.
    expect(resets, hasLength(1));
  });

  test(
    'a 422 leaves the language, the cache and the catalog untouched',
    () async {
      final env = await build(
        profileError: const ApiException(
          code: ApiErrorCode.validationError,
          message: 'unknown language',
          status: 422,
        ),
      );
      final resets = listenResets(env.container);

      await expectLater(
        env.model.changeStudiedLanguage('xx'),
        throwsA(isA<ApiException>()),
      );
      // The catalog is not touched until the profile accepts the language.
      expect(env.lessons.cleared, isFalse);
      await pumpEventQueue();
      expect(resets, isEmpty);
      expect(
        env.container.read(authServiceProvider).session.user?.studiedLanguage,
        'en',
      );
    },
  );
}

class _EmptyLibrary implements LibraryRepository {
  @override
  Future<LibraryRoot> getRoot() async => LibraryRoot.empty;
}
