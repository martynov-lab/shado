// Turning pasted text into phrases of a set.

final RegExp _sentence = RegExp(r'[^.?!]+[.?!]*');
final RegExp _spaces = RegExp(r'\s+');
final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Splits [text] into phrases after `.`, `?` and `!`; the marks stay with
/// their phrase,
/// line breaks and repeated spaces turn into one space, and pieces without
/// a letter or digit are dropped.
List<String> splitIntoPhrases(String text) => [
  for (final match in _sentence.allMatches(text))
    if (match.group(0)!.replaceAll(_spaces, ' ').trim() case final phrase
        when _wordChar.hasMatch(phrase))
      phrase,
];
