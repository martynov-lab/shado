import '../../domain/entities/translation_language.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/translation_remote_datasource.dart';

/// Translation straight from the server; the server caches results itself.
class TranslationRepositoryImpl implements TranslationRepository {
  const TranslationRepositoryImpl(this._remote);

  final TranslationRemoteDataSource _remote;

  @override
  Future<List<TranslationLanguage>> getLanguages() => _remote.languages();

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  }) => _remote.translate(texts, sourceLang: sourceLang);
}
