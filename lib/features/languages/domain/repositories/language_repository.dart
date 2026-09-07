import '../entities/language.dart';

/// Language directory access.
abstract interface class LanguageRepository {
  /// Languages available for study together with their accents.
  Future<List<Language>> getLanguages();
}
