import '../../domain/entities/language.dart';
import '../../domain/repositories/language_repository.dart';
import '../datasources/language_remote_datasource.dart';

/// Language directory; the server changes it with a release only.
class LanguageRepositoryImpl implements LanguageRepository {
  const LanguageRepositoryImpl(this._remote);

  final LanguageRemoteDataSource _remote;

  @override
  Future<List<Language>> getLanguages() => _remote.list();
}
