import 'package:flutter_test/flutter_test.dart';

import 'package:shado/features/progress/domain/item_keys.dart';

void main() {
  group('segmentItemKey', () {
    // Reference vectors from EXPRESSIONS_SPEC.md §3.1, shared with the server.
    const vectors = {
      '  Hello   there. ': 's:92ea4f7debacecc2',
      "  Where's\tthe   check-in\ndesk? ": 's:a921782458bdd544',
      'Ça va ?': 's:20ca9e3c80c9a4e2',
      "İstanbul'a GİDİYORUM.": 's:8dbc5a41572e280f',
      'ÉCOLE': 's:f0f772e182a4941e',
    };

    for (final MapEntry(key: text, value: expected) in vectors.entries) {
      test('matches the server for "$text"', () {
        expect(segmentItemKey(text), expected);
      });
    }

    test('ignores spacing and case differences', () {
      expect(segmentItemKey('Hello there.'), segmentItemKey(' HELLO  there. '));
    });
  });

  test('phraseItemKey prefixes the phrase id', () {
    expect(phraseItemKey('6a1f'), 'p:6a1f');
  });
}
