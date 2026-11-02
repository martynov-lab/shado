import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';
import 'package:shado/features/translation/domain/entities/translation_language.dart';
import 'package:shado/features/translation/domain/repositories/translation_repository.dart';
import 'package:shado/features/translation/domain/services/phrase_translator.dart';
import 'package:shado/features/translation/domain/services/translation_language_service.dart';
import 'package:shado/features/translation/domain/usecases/get_translation_languages.dart';
import 'package:shado/features/translation/domain/usecases/translate_texts.dart';

import '../presentation/fake_auth_repository.dart';

/// Translates by prefixing the text and records every request.
class _FakeTranslationRepository implements TranslationRepository {
  final List<List<String>> requests = [];

  @override
  Future<List<TranslationLanguage>> getLanguages() async => const [];

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  }) async {
    requests.add(texts);
    return [for (final text in texts) 'ru:$text'];
  }
}

class _OnlineMonitor implements NetworkMonitor {
  @override
  Stream<bool> get onlineChanges => const Stream.empty();

  @override
  Future<bool> isOnline() async => true;
}

void main() {
  group('translateBatches', () {
    test('keeps everything in one batch within the limits', () {
      expect(translateBatches(['a', 'b', 'c']), [
        ['a', 'b', 'c'],
      ]);
    });

    test('splits by the text count limit', () {
      final texts = List.generate(kMaxTranslateBatchTexts + 1, (i) => '$i');

      final batches = translateBatches(texts);

      expect(batches.map((b) => b.length), [kMaxTranslateBatchTexts, 1]);
    });

    test('splits by the character limit', () {
      final long = 'x' * (kMaxTranslateBatchChars ~/ 2 + 1);

      expect(translateBatches([long, long]), hasLength(2));
    });
  });

  group('PhraseTranslator', () {
    late _FakeTranslationRepository repository;
    late PhraseTranslator translator;

    setUp(() async {
      repository = _FakeTranslationRepository();
      final AuthRepository authRepository = FakeAuthRepository(
        user: testUser(),
      );
      final auth = AuthService(
        repository: authRepository,
        signIn: SignIn(authRepository),
        signUp: SignUp(authRepository),
        signOut: SignOut(authRepository),
        getCurrentUser: GetCurrentUser(authRepository),
        updateProfile: UpdateProfile(authRepository),
        network: _OnlineMonitor(),
      );
      await auth.restore();
      final languages = TranslationLanguageService(
        getLanguages: GetTranslationLanguages(repository),
        auth: auth,
      );
      addTearDown(() {
        languages.dispose();
        auth.dispose();
      });
      translator = PhraseTranslator(
        translate: TranslateTexts(repository),
        languages: languages,
      );
    });

    test('translates in order and sends a repeated text once', () async {
      final result = await translator.translateAll([
        'a',
        'b',
        'a',
      ], sourceLang: 'en');

      expect(result, ['ru:a', 'ru:b', 'ru:a']);
      expect(repository.requests, [
        ['a', 'b'],
      ]);
    });

    test('a cached translation costs no request', () async {
      await translator.translate('a', sourceLang: 'en');

      expect(translator.cached('a', sourceLang: 'en'), 'ru:a');
      await translator.translate('a', sourceLang: 'en');
      expect(repository.requests, hasLength(1));
    });

    test('the profile default is Russian, so ru to ru is pointless', () {
      expect(translator.targetLanguage, 'ru');
      expect(translator.isSameLanguage('ru'), isTrue);
      expect(translator.isSameLanguage('en'), isFalse);
    });
  });
}
