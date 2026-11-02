import 'audio_upload.dart';
import 'phrase.dart';

/// A phrase being edited: its text, translations and the audio voiced for
/// the text it had at that moment.
class PhraseDraft {
  const PhraseDraft({
    required this.id,
    this.text = '',
    this.translations = const {},
    this.audioId,
    this.audioPath = '',
    this.durationMs = 0,
    this.voicedText,
    this.startMs,
    this.endMs,
    this.sourceLessonId,
  });

  /// A saved phrase: its audio matches its text.
  factory PhraseDraft.fromPhrase(Phrase phrase) => PhraseDraft(
    id: phrase.id,
    text: phrase.text,
    translations: phrase.translations,
    audioId: phrase.audioId,
    audioPath: phrase.audioPath,
    durationMs: phrase.durationMs,
    voicedText: phrase.text,
    startMs: phrase.startMs,
    endMs: phrase.endMs,
    sourceLessonId: phrase.sourceLessonId,
  );

  final String id;
  final String text;
  final Map<String, String> translations;
  final String? audioId;
  final String audioPath;
  final int durationMs;

  /// The text the audio was made for.
  final String? voicedText;

  final int? startMs;
  final int? endMs;
  final String? sourceLessonId;

  String get trimmedText => text.trim();

  bool get hasText => trimmedText.isNotEmpty;

  /// Whether the phrase has no audio or the text changed after voicing.
  bool get needsVoice =>
      hasText && (audioId == null || voicedText != trimmedText);

  /// Whether the phrase can be saved as it is.
  bool get isReady => hasText && !needsVoice;

  /// Where the audio plays from and to; the story range for a story phrase.
  int get playStartMs => startMs ?? 0;
  int get playEndMs => endMs ?? durationMs;

  String translationFor(String language) => translations[language] ?? '';

  PhraseDraft withText(String text) => _copy(text: text);

  PhraseDraft withTranslation(String language, String value) =>
      _copy(translations: {...translations, language: value});

  /// The phrase voiced anew: its own file replaces a story range.
  PhraseDraft withAudio(AudioUpload audio) => PhraseDraft(
    id: id,
    text: text,
    translations: translations,
    audioId: audio.audioId,
    audioPath: audio.localPath,
    durationMs: audio.durationMs,
    voicedText: trimmedText,
  );

  /// The phrase to save; call only when [isReady].
  Phrase toPhrase() => Phrase(
    id: id,
    text: trimmedText,
    translations: translations,
    audioId: audioId!,
    audioPath: audioPath,
    durationMs: durationMs,
    startMs: startMs,
    endMs: endMs,
    sourceLessonId: sourceLessonId,
  );

  PhraseDraft _copy({String? text, Map<String, String>? translations}) =>
      PhraseDraft(
        id: id,
        text: text ?? this.text,
        translations: translations ?? this.translations,
        audioId: audioId,
        audioPath: audioPath,
        durationMs: durationMs,
        voicedText: voicedText,
        startMs: startMs,
        endMs: endMs,
        sourceLessonId: sourceLessonId,
      );
}
