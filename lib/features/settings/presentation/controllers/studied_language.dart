/// Изучаемый язык — короткий код (`studied_language`, §6) с подписью для UI.
///
/// Список закрытый на клиенте: сервер хранит произвольный код, а мы показываем
/// знакомые названия. Незнакомый код не теряем — [studiedLanguageLabel]
/// возвращает его как есть.
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

  /// Код в протоколе сервера.
  final String code;

  /// Название на русском для списка и строки настроек.
  final String label;

  /// Язык по коду; `null` — код незнакомый (или пустой).
  static StudiedLanguage? parse(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final language in StudiedLanguage.values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// Подпись изучаемого языка для UI: название знакомого кода или сам код, если
/// он незнаком. `null`/пустой — «Не выбран».
String studiedLanguageLabel(String? code) {
  if (code == null || code.isEmpty) return 'Не выбран';
  return StudiedLanguage.parse(code)?.label ?? code;
}
