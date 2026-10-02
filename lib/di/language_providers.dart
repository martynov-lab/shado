import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/features/languages/data/datasources/language_remote_datasource.dart';
import 'package:shado/features/languages/data/repositories/language_repository_impl.dart';
import 'package:shado/features/languages/domain/repositories/language_repository.dart';
import 'package:shado/features/languages/domain/services/language_service.dart';
import 'package:shado/features/languages/domain/usecases/get_languages.dart';

/// Dependency wiring for the language directory.
final languageRemoteDataSourceProvider = Provider<LanguageRemoteDataSource>(
  (ref) => ApiLanguageRemoteDataSource(ref.watch(apiClientProvider)),
);

final languageRepositoryProvider = Provider<LanguageRepository>(
  (ref) => LanguageRepositoryImpl(ref.watch(languageRemoteDataSourceProvider)),
);

final getLanguagesProvider = Provider<GetLanguages>(
  (ref) => GetLanguages(ref.watch(languageRepositoryProvider)),
);

final languageServiceProvider = Provider<LanguageService>((ref) {
  final service = LanguageService(
    getLanguages: ref.watch(getLanguagesProvider),
    auth: ref.watch(authServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
