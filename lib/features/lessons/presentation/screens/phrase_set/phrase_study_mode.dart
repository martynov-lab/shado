/// How the phrase set is studied: listening and repeating, or recalling a
/// phrase from its translation.
enum PhraseStudyMode {
  listen('Listen'),
  recall('Recall');

  const PhraseStudyMode(this.label);

  final String label;
}
