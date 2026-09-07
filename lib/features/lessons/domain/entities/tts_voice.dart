/// AI voice-over: the voice directory and a listening sample.
library;

/// A synthesis voice offered by the provider.
class TtsVoice {
  const TtsVoice({required this.name, this.description = ''});

  factory TtsVoice.fromJson(Map<String, dynamic> json) => TtsVoice(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );

  final String name;

  /// Short characteristic shown next to the name.
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TtsVoice && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'TtsVoice($name)';
}

/// Voice directory; an empty list means the provider offers no choice.
class TtsVoices {
  const TtsVoices({this.items = const [], this.defaultVoice});

  final List<TtsVoice> items;

  /// Voice the server uses when none is sent.
  final String? defaultVoice;

  bool get isEmpty => items.isEmpty;
}

/// Voice sample: a downloaded file and the phrase it speaks.
class TtsPreview {
  const TtsPreview({
    required this.localPath,
    this.text = '',
    this.cached = false,
  });

  /// Path to the sample outside the lesson audio cache.
  final String localPath;

  /// Phrase the server picked for the current language.
  final String text;

  /// The same text and voice came from the server cache — no quota spent.
  final bool cached;
}
