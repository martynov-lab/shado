import '../usecases/translate_texts.dart';
import 'translation_language_service.dart';

/// Machine translation into the profile translation language, remembered
/// for the session so a revisited phrase costs no request.
class PhraseTranslator {
  PhraseTranslator({
    required TranslateTexts translate,
    required TranslationLanguageService languages,
  }) : _translate = translate,
       _languages = languages;

  final TranslateTexts _translate;
  final TranslationLanguageService _languages;
  final Map<String, String> _cache = {};

  /// Code of the language translations go into.
  String get targetLanguage => _languages.currentCode;

  /// Whether translating from [sourceLang] would return the text unchanged.
  bool isSameLanguage(String sourceLang) => sourceLang == targetLanguage;

  /// Cached translation of [text]; `null` when it was not requested yet.
  String? cached(String text, {required String sourceLang}) =>
      _cache[_key(text, sourceLang)];

  Future<String> translate(String text, {required String sourceLang}) async {
    final result = await translateAll([text], sourceLang: sourceLang);
    return result.single;
  }

  /// Translates [texts] keeping their order; cached ones are not sent.
  Future<List<String>> translateAll(
    List<String> texts, {
    required String sourceLang,
  }) async {
    final missing = <String>{
      for (final text in texts)
        if (!_cache.containsKey(_key(text, sourceLang))) text,
    }.toList();
    if (missing.isNotEmpty) {
      final translated = await _translate(missing, sourceLang: sourceLang);
      for (var i = 0; i < missing.length && i < translated.length; i++) {
        _cache[_key(missing[i], sourceLang)] = translated[i];
      }
    }
    return [for (final text in texts) _cache[_key(text, sourceLang)] ?? ''];
  }

  String _key(String text, String sourceLang) =>
      '$sourceLang|$targetLanguage|$text';
}
