import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/phrase_deck.dart';

void main() {
  group('shuffleDeck', () {
    test('keeps every phrase exactly once', () {
      final shuffled = shuffleDeck([0, 1, 2, 3, 4, 5], Random(7));

      expect(shuffled.toSet(), {0, 1, 2, 3, 4, 5});
      expect(shuffled, hasLength(6));
    });

    test('the same seed gives the same order', () {
      expect(
        shuffleDeck([0, 1, 2, 3, 4, 5], Random(7)),
        shuffleDeck([0, 1, 2, 3, 4, 5], Random(7)),
      );
    });

    test('does not change the deck it got', () {
      final deck = [0, 1, 2, 3];

      shuffleDeck(deck, Random(1));

      expect(deck, [0, 1, 2, 3]);
    });
  });

  group('phrasesRatedBetween', () {
    const keys = ['p:a', 'p:b', 'p:c', 'p:d'];
    const stars = {'p:a': 5, 'p:b': 2, 'p:d': 3};

    test('picks unrated phrases with a zero range', () {
      expect(phrasesRatedBetween(keys, stars, minStars: 0, maxStars: 0), [2]);
    });

    test('picks weak phrases by stars', () {
      expect(phrasesRatedBetween(keys, stars, minStars: 1, maxStars: 3), [
        1,
        3,
      ]);
    });
  });
}
