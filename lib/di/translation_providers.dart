import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/features/translation/data/datasources/translation_remote_datasource.dart';
import 'package:shado/features/translation/data/repositories/translation_repository_impl.dart';
import 'package:shado/features/translation/domain/repositories/translation_repository.dart';
import 'package:shado/features/translation/domain/services/phrase_translator.dart';
import 'package:shado/features/translation/domain/services/translation_language_service.dart';
import 'package:shado/features/translation/domain/usecases/get_translation_languages.dart';
import 'package:shado/features/translation/domain/usecases/translate_texts.dart';

/// Dependency wiring for phrase translation.
final translationRemoteDataSourceProvider =
    Provider<TranslationRemoteDataSource>(
      (ref) => ApiTranslationRemoteDataSource(ref.watch(apiClientProvider)),
    );

final translationRepositoryProvider = Provider<TranslationRepository>(
  (ref) =>
      TranslationRepositoryImpl(ref.watch(translationRemoteDataSourceProvider)),
);

final getTranslationLanguagesProvider = Provider<GetTranslationLanguages>(
  (ref) => GetTranslationLanguages(ref.watch(translationRepositoryProvider)),
);

final translateTextsProvider = Provider<TranslateTexts>(
  (ref) => TranslateTexts(ref.watch(translationRepositoryProvider)),
);

final translationLanguageServiceProvider = Provider<TranslationLanguageService>(
  (ref) {
    final service = TranslationLanguageService(
      getLanguages: ref.watch(getTranslationLanguagesProvider),
      auth: ref.watch(authServiceProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);

final phraseTranslatorProvider = Provider<PhraseTranslator>(
  (ref) => PhraseTranslator(
    translate: ref.watch(translateTextsProvider),
    languages: ref.watch(translationLanguageServiceProvider),
  ),
);
