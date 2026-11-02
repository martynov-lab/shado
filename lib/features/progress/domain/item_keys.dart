import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Rating key of a phrase in a phrase set.
String phraseItemKey(String phraseId) => 'p:$phraseId';

/// Rating key of a story segment: a hash of its normalized text, so the
/// rating survives re-splitting while the text stays the same.
String segmentItemKey(String text) {
  final normalized = text
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      // Dart drops the dot of the Turkish İ; the server keeps it as U+0307.
      .replaceAll('\u0130', 'i\u0307')
      .toLowerCase();
  final digest = sha256.convert(utf8.encode(normalized)).toString();
  return 's:${digest.substring(0, 16)}';
}
