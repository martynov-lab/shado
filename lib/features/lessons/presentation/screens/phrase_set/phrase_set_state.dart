import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/phrase.dart';
import 'phrase_study_mode.dart';

/// State of the phrase set screen: the deck, where in it the card is and how
/// it plays.
class PhraseSetState {
  const PhraseSetState({
    required this.lesson,
    required this.deck,
    required this.order,
    this.position = 0,
    this.mode = PhraseStudyMode.listen,
    this.isFlipped = false,
    this.isPlaying = false,
    this.isLooping = false,
    this.isRepeating = false,
    this.isShuffled = false,
    this.isSelecting = false,
    this.selection = const {},
    this.speed = kNormalSpeed,
  });

  /// The whole set as the deck in lesson order.
  factory PhraseSetState.initial(Lesson lesson, {required double speed}) {
    final all = [for (var i = 0; i < lesson.phrases.length; i++) i];
    return PhraseSetState(lesson: lesson, deck: all, order: all, speed: speed);
  }

  final Lesson lesson;

  /// Indices of the studied phrases in lesson order.
  final List<int> deck;

  /// The deck in play order: as is or shuffled.
  final List<int> order;

  /// Index into [order] of the card on screen.
  final int position;

  final PhraseStudyMode mode;

  /// Recall: the card shows the phrase instead of its translation.
  final bool isFlipped;

  final bool isPlaying;

  /// Listen: the deck plays round and round by itself.
  final bool isLooping;

  /// The current phrase repeats until switched off.
  final bool isRepeating;

  final bool isShuffled;

  /// Whether deck selection mode is on.
  final bool isSelecting;

  /// Phrase indices picked in selection mode.
  final Set<int> selection;

  final double speed;

  bool get isEmpty => order.isEmpty;

  /// Whether the deck is a part of the set.
  bool get isPartialDeck => deck.length < lesson.phrases.length;

  int get phraseIndex => order[position.clamp(0, order.length - 1)];

  Phrase get current => lesson.phrases[phraseIndex];

  /// Whether the card shows the phrase rather than its translation.
  bool get showsPhrase => mode == PhraseStudyMode.listen || isFlipped;

  bool get isSlow => speed == kSlowSpeed;

  /// Position after a step of [delta], wrapping around the deck.
  int positionAfter(int delta) {
    if (order.isEmpty) return 0;
    return (position + delta) % order.length;
  }

  PhraseSetState copyWith({
    Lesson? lesson,
    List<int>? deck,
    List<int>? order,
    int? position,
    PhraseStudyMode? mode,
    bool? isFlipped,
    bool? isPlaying,
    bool? isLooping,
    bool? isRepeating,
    bool? isShuffled,
    bool? isSelecting,
    Set<int>? selection,
    double? speed,
  }) => PhraseSetState(
    lesson: lesson ?? this.lesson,
    deck: deck ?? this.deck,
    order: order ?? this.order,
    position: position ?? this.position,
    mode: mode ?? this.mode,
    isFlipped: isFlipped ?? this.isFlipped,
    isPlaying: isPlaying ?? this.isPlaying,
    isLooping: isLooping ?? this.isLooping,
    isRepeating: isRepeating ?? this.isRepeating,
    isShuffled: isShuffled ?? this.isShuffled,
    isSelecting: isSelecting ?? this.isSelecting,
    selection: selection ?? this.selection,
    speed: speed ?? this.speed,
  );
}
