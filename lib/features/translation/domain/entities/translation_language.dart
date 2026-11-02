/// Language phrases can be translated into.
class TranslationLanguage {
  const TranslationLanguage({
    required this.code,
    required this.name,
    this.nativeName = '',
  });

  factory TranslationLanguage.fromJson(Map<String, dynamic> json) =>
      TranslationLanguage(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nativeName: json['native_name'] as String? ?? '',
      );

  final String code;
  final String name;

  /// Language name in the language itself.
  final String nativeName;

  /// Label for the UI; without a name the code itself is shown.
  String get label => name.isEmpty ? code : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationLanguage && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'TranslationLanguage($code, "$name")';
}
