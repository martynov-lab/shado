import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/phrase_text.dart';

void main() {
  test('splits at every dot and keeps the dot with its phrase', () {
    expect(splitIntoPhrases('Hello there. How are you. Fine'), [
      'Hello there.',
      'How are you.',
      'Fine',
    ]);
  });

  test('question and exclamation marks end a phrase too', () {
    expect(splitIntoPhrases('Where is the desk? Over there! Thanks.'), [
      'Where is the desk?',
      'Over there!',
      'Thanks.',
    ]);
  });

  test('a run of marks stays with its phrase', () {
    expect(splitIntoPhrases('Really?! Wait... OK'), [
      'Really?!',
      'Wait...',
      'OK',
    ]);
  });

  test('line breaks and repeated spaces become one space', () {
    expect(splitIntoPhrases('  Where is\nthe   desk.\tOver there.  '), [
      'Where is the desk.',
      'Over there.',
    ]);
  });

  test('lone punctuation is dropped', () {
    expect(splitIntoPhrases('Wait. . ! ?'), ['Wait.']);
  });

  test('empty text gives no phrases', () {
    expect(splitIntoPhrases('  \n '), isEmpty);
  });

  test('letters of any alphabet count as a phrase', () {
    expect(splitIntoPhrases('Ça va. Привет.'), ['Ça va.', 'Привет.']);
  });
}
