/// Lesson kind: a story cut into segments or a set of separate phrases.
enum LessonKind {
  story('story', 'Story'),
  expressions('expressions', 'Phrases');

  const LessonKind(this.wire, this.label);

  /// JSON value.
  final String wire;

  final String label;

  /// An unknown or missing value counts as a story.
  static LessonKind parse(String? raw) {
    for (final kind in values) {
      if (kind.wire == raw) return kind;
    }
    return story;
  }
}
