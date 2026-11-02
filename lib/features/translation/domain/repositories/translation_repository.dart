import '../entities/translation_language.dart';

/// Phrase translation on the server.
abstract interface class TranslationRepository {
  /// Languages phrases can be translated into.
  Future<List<TranslationLanguage>> getLanguages();

  /// Translates [texts] from [sourceLang] into the profile translation
  /// language; the result keeps the order of [texts].
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  });
}
