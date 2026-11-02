import '../repositories/translation_repository.dart';

/// Server limits of one batch translation request.
const int kMaxTranslateBatchTexts = 200;
const int kMaxTranslateBatchChars = 10000;

/// Translates any number of texts, split into batches the server accepts.
class TranslateTexts {
  const TranslateTexts(this._repository);

  final TranslationRepository _repository;

  Future<List<String>> call(
    List<String> texts, {
    required String sourceLang,
  }) async {
    final result = <String>[];
    for (final batch in translateBatches(texts)) {
      result.addAll(await _repository.translate(batch, sourceLang: sourceLang));
    }
    return result;
  }
}

/// Splits [texts] into consecutive batches within the server limits.
List<List<String>> translateBatches(List<String> texts) {
  final batches = <List<String>>[];
  var current = <String>[];
  var chars = 0;
  for (final text in texts) {
    final full =
        current.length >= kMaxTranslateBatchTexts ||
        chars + text.length > kMaxTranslateBatchChars;
    if (current.isNotEmpty && full) {
      batches.add(current);
      current = <String>[];
      chars = 0;
    }
    current.add(text);
    chars += text.length;
  }
  if (current.isNotEmpty) batches.add(current);
  return batches;
}
