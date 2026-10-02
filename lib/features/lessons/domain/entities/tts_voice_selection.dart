/// Voice and accent chosen for the AI voice-over.
class TtsVoiceSelection {
  const TtsVoiceSelection({this.voice, this.accent});

  /// `null` lets the server use its default voice.
  final String? voice;

  /// Voice-over accent; `null` for languages without accents.
  final String? accent;

  TtsVoiceSelection copyWith({String? voice, String? accent}) =>
      TtsVoiceSelection(
        voice: voice ?? this.voice,
        accent: accent ?? this.accent,
      );
}
