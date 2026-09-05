/// Studied language: the protocol code and a UI label.
enum StudiedLanguage {
  en('en', 'Английский'),
  es('es', 'Испанский'),
  fr('fr', 'Французский'),
  de('de', 'Немецкий'),
  it('it', 'Итальянский'),
  pt('pt', 'Португальский'),
  ru('ru', 'Русский'),
  zh('zh', 'Китайский'),
  ja('ja', 'Японский'),
  ko('ko', 'Корейский');

  const StudiedLanguage(this.code, this.label);

  /// Code in the server protocol.
  final String code;

  /// Language name for the UI.
  final String label;

  /// Language by code; `null` when the code is unknown or empty.
  static StudiedLanguage? parse(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final language in StudiedLanguage.values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// Studied language label; an unknown code is returned as is.
String studiedLanguageLabel(String? code) {
  if (code == null || code.isEmpty) return 'Не выбран';
  return StudiedLanguage.parse(code)?.label ?? code;
}
