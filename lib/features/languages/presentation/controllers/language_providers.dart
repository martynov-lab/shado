import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/language_remote_datasource.dart';
import '../../data/repositories/language_repository_impl.dart';
import '../../domain/entities/language.dart';
import '../../domain/repositories/language_repository.dart';
import '../../domain/usecases/get_languages.dart';

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

/// Language directory; kept for the whole session — it changes with a server
/// release.
final languagesProvider = FutureProvider<List<Language>>(
  (ref) => ref.watch(getLanguagesProvider)(),
);

/// Language from the profile matched against the directory; `null` while the
/// directory is loading or when the code is unknown.
final currentLanguageProvider = Provider<Language?>((ref) {
  final code = ref.watch(
    authControllerProvider.select((state) => state.user?.studiedLanguage),
  );
  if (code == null || code.isEmpty) return null;
  final languages = ref.watch(languagesProvider).value ?? const <Language>[];
  for (final language in languages) {
    if (language.code == code) return language;
  }
  return null;
});

/// Accents of the current language; empty for a language without them and
/// while the directory is loading.
final currentAccentsProvider = Provider<List<Accent>>(
  (ref) => ref.watch(currentLanguageProvider)?.accents ?? const [],
);

/// Studied language name for the settings screen; an unknown code is shown as
/// is.
final studiedLanguageLabelProvider = Provider<String>((ref) {
  final code = ref.watch(
    authControllerProvider.select((state) => state.user?.studiedLanguage),
  );
  if (code == null || code.isEmpty) return 'Не выбран';
  return ref.watch(currentLanguageProvider)?.label ?? code;
});
