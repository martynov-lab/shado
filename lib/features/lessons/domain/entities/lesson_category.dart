/// Speaker accent, English level and lesson topic.
library;

/// Speaker accent; [wire] goes to the server, [label] is shown in the UI.
enum LessonAccent {
  us('US', 'Американский'),
  uk('UK', 'Британский');

  const LessonAccent(this.wire, this.label);

  /// JSON value — uppercase `US` / `UK`.
  final String wire;

  final String label;

  /// Parses an accent; `null` when it is missing or unknown.
  static LessonAccent? parse(String? raw) {
    if (raw == null) return null;
    for (final accent in values) {
      if (accent.wire == raw) return accent;
    }
    return null;
  }
}

/// English level on the CEFR scale.
enum LessonLevel {
  a1('a1', 'A1 — начальный'),
  a2('a2', 'A2 — элементарный'),
  b1('b1', 'B1 — средний'),
  b2('b2', 'B2 — выше среднего'),
  c1('c1', 'C1 — продвинутый'),
  c2('c2', 'C2 — владение в совершенстве');

  const LessonLevel(this.wire, this.label);

  /// JSON value — lowercase `a1`…`c2`.
  final String wire;

  final String label;

  static LessonLevel? parse(String? raw) {
    if (raw == null) return null;
    for (final level in values) {
      if (level.wire == raw) return level;
    }
    return null;
  }
}

/// Lesson topic from the server directory.
class Topic {
  const Topic({required this.id, required this.name, this.isDefault = false});

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
  );

  final String id;
  final String name;

  /// The default topic the server assigns itself.
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Topic($id, "$name")';
}
