import '../entities/language.dart';
import '../repositories/language_repository.dart';

/// Language directory for the settings picker and the accent fields.
class GetLanguages {
  const GetLanguages(this._repository);

  final LanguageRepository _repository;

  Future<List<Language>> call() => _repository.getLanguages();
}
