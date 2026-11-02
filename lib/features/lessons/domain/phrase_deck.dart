// The deck of a phrase set: which phrases are studied and in what order.

import 'dart:math';

/// [deck] in a random order drawn from [random].
List<int> shuffleDeck(List<int> deck, Random random) =>
    List.of(deck)..shuffle(random);

/// Indices of the phrases whose rating lies in [minStars]..[maxStars]; an
/// unrated phrase counts as zero.
List<int> phrasesRatedBetween(
  List<String> itemKeys,
  Map<String, int> stars, {
  required int minStars,
  required int maxStars,
}) => [
  for (var i = 0; i < itemKeys.length; i++)
    if ((stars[itemKeys[i]] ?? 0) >= minStars &&
        (stars[itemKeys[i]] ?? 0) <= maxStars)
      i,
];
