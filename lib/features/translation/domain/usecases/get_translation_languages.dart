import '../entities/translation_language.dart';
import '../repositories/translation_repository.dart';

/// Translation language directory for the settings picker.
class GetTranslationLanguages {
  const GetTranslationLanguages(this._repository);

  final TranslationRepository _repository;

  Future<List<TranslationLanguage>> call() => _repository.getLanguages();
}
