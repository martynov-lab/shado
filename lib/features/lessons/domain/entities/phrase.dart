/// A phrase of a phrase set: text, translations and its own audio.
class Phrase {
  const Phrase({
    required this.id,
    required this.text,
    required this.audioId,
    required this.durationMs,
    this.translations = const {},
    this.audioPath = '',
    this.startMs,
    this.endMs,
    this.sourceLessonId,
  });

  final String id;
  final String text;

  /// Translations by language code.
  final Map<String, String> translations;

  final String audioId;

  /// Local copy of the audio; empty until it is downloaded.
  final String audioPath;

  /// Length of what plays: the file or the story range.
  final int durationMs;

  /// Range inside a story file; `null` for a phrase with its own file.
  final int? startMs;
  final int? endMs;

  /// The story the phrase was taken from.
  final String? sourceLessonId;

  /// Where playback starts in the file.
  int get playStartMs => startMs ?? 0;

  /// Where playback stops in the file.
  int get playEndMs => endMs ?? durationMs;

  /// Translation into [language]; `null` when the author did not add one.
  String? translationFor(String language) {
    final translation = translations[language];
    return translation == null || translation.isEmpty ? null : translation;
  }

  Phrase copyWith({
    String? text,
    Map<String, String>? translations,
    String? audioId,
    String? audioPath,
    int? durationMs,
  }) => Phrase(
    id: id,
    text: text ?? this.text,
    translations: translations ?? this.translations,
    audioId: audioId ?? this.audioId,
    audioPath: audioPath ?? this.audioPath,
    durationMs: durationMs ?? this.durationMs,
    startMs: startMs,
    endMs: endMs,
    sourceLessonId: sourceLessonId,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Phrase) return false;
    if (other.translations.length != translations.length) return false;
    for (final MapEntry(:key, :value) in translations.entries) {
      if (other.translations[key] != value) return false;
    }
    return other.id == id &&
        other.text == text &&
        other.audioId == audioId &&
        other.audioPath == audioPath &&
        other.durationMs == durationMs &&
        other.startMs == startMs &&
        other.endMs == endMs &&
        other.sourceLessonId == sourceLessonId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    text,
    audioId,
    audioPath,
    durationMs,
    startMs,
    endMs,
    sourceLessonId,
  );

  @override
  String toString() => 'Phrase($id, "$text")';
}
