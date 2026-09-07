/// Studied language directory: languages and their accents.
library;

/// Speaker accent of a language; [code] goes to the server.
class Accent {
  const Accent({
    required this.code,
    required this.name,
    this.isDefault = false,
  });

  factory Accent.fromJson(Map<String, dynamic> json) => Accent(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
  );

  final String code;
  final String name;

  /// The accent the server picks when none is sent.
  final bool isDefault;

  /// Label for the UI; without a name the code itself is shown.
  String get label => name.isEmpty ? code : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Accent && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'Accent($code, "$name")';
}

/// Language available for study.
class Language {
  const Language({
    required this.code,
    required this.name,
    this.nativeName = '',
    this.isDefault = false,
    this.accents = const [],
  });

  factory Language.fromJson(Map<String, dynamic> json) => Language(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nativeName: json['native_name'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
    accents: [
      for (final accent in (json['accents'] as List<dynamic>? ?? const []))
        Accent.fromJson(Map<String, dynamic>.from(accent as Map)),
    ],
  );

  final String code;
  final String name;

  /// Language name in the language itself.
  final String nativeName;

  /// The language a new profile starts with.
  final bool isDefault;

  /// Accents of the language; empty means the language has none.
  final List<Accent> accents;

  bool get hasAccents => accents.isNotEmpty;

  /// Label for the UI; without a name the code itself is shown.
  String get label => name.isEmpty ? code : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'Language($code, "$name", ${accents.length} акцентов)';
}
