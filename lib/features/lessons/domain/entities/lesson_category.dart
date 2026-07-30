/// Акцент диктора и уровень английского — закрытые списки из §6 спецификации.
///
/// Сервер меняет их только релизом, поэтому значения живут в клиенте и за ними
/// не нужно ходить по сети. Тема, наоборот, справочник — см. [Topic].
library;

/// Акцент диктора. На сервер уезжает [wire], пользователю показывается [label].
enum LessonAccent {
  us('US', 'Американский'),
  uk('UK', 'Британский');

  const LessonAccent(this.wire, this.label);

  /// Значение в JSON: сервер ждёт заглавные `US` / `UK`.
  final String wire;

  final String label;

  /// `null` — значения нет или оно незнакомое. Подставлять на его место
  /// что-то по умолчанию нельзя: это соврало бы про содержимое урока.
  static LessonAccent? parse(String? raw) {
    if (raw == null) return null;
    for (final accent in values) {
      if (accent.wire == raw) return accent;
    }
    return null;
  }
}

/// Уровень английского по CEFR.
enum LessonLevel {
  a1('a1', 'A1 — начальный'),
  a2('a2', 'A2 — элементарный'),
  b1('b1', 'B1 — средний'),
  b2('b2', 'B2 — выше среднего'),
  c1('c1', 'C1 — продвинутый'),
  c2('c2', 'C2 — владение в совершенстве');

  const LessonLevel(this.wire, this.label);

  /// Значение в JSON: сервер ждёт строчные `a1`…`c2`.
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

/// Тема урока из справочника сервера (`GET /v1/topics`).
///
/// В отличие от акцента и уровня темы правит владелец, поэтому список
/// запрашивается, а не зашит в клиент. Название может измениться, [id] — нет:
/// в кеше и фильтрах опираемся на него.
class Topic {
  const Topic({required this.id, required this.name, this.isDefault = false});

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
  );

  final String id;
  final String name;

  /// Тема, которую сервер ставит уроку сам, когда тему не выбрали («Other»).
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
