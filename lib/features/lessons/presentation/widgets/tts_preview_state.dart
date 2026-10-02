/// Which voice sample is being fetched or played and what the phrase is.
class TtsPreviewState {
  const TtsPreviewState({this.loadingVoice, this.playingVoice, this.text = ''});

  /// Voice whose sample is being fetched; `null` when nothing is loading.
  final String? loadingVoice;

  /// Voice being played right now.
  final String? playingVoice;

  /// Phrase of the last sample.
  final String text;
}
