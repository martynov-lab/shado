import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lesson_category.dart';

/// Lesson category fields: accent, level and topic.
class LessonCategoryFields extends StatelessWidget {
  const LessonCategoryFields({
    super.key,
    required this.accent,
    required this.level,
    required this.topicId,
    required this.topics,
    required this.isBusy,
    required this.onAccentChanged,
    required this.onLevelChanged,
    required this.onTopicChanged,
  });

  /// Selected values; `null` when the field was never filled.
  final LessonAccent? accent;
  final LessonLevel? level;

  /// Selected topic; `null` means no topic.
  final String? topicId;

  /// Topic directory from the server; the field hint is built from it.
  final AsyncValue<List<Topic>> topics;

  /// An upload is running — the fields are locked.
  final bool isBusy;

  final ValueChanged<LessonAccent?> onAccentChanged;
  final ValueChanged<LessonLevel?> onLevelChanged;
  final ValueChanged<String?> onTopicChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = topics.value ?? const <Topic>[];
    // The dropdown throws when the selected value is not among the items.
    final selectedTopic = available.any((topic) => topic.id == topicId)
        ? topicId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<LessonAccent>(
                key: const ValueKey('dropdown-accent'),
                initialValue: accent,
                decoration: const InputDecoration(labelText: 'Акцент'),
                items: [
                  for (final value in LessonAccent.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: isBusy ? null : onAccentChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<LessonLevel>(
                key: const ValueKey('dropdown-level'),
                initialValue: level,
                decoration: const InputDecoration(labelText: 'Уровень'),
                // The collapsed field keeps only the level code.
                selectedItemBuilder: (_) => [
                  for (final value in LessonLevel.values)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(value.wire.toUpperCase()),
                    ),
                ],
                items: [
                  for (final value in LessonLevel.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: isBusy ? null : onLevelChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          key: const ValueKey('dropdown-topic'),
          initialValue: selectedTopic,
          decoration: InputDecoration(
            labelText: 'Тема',
            helperText: switch (topics) {
              AsyncError() =>
                'Справочник тем не загрузился — урок создастся '
                    'с темой по умолчанию',
              AsyncLoading() => 'Загружаем справочник тем…',
              _ =>
                'Необязательно: без выбора сервер поставит тему по умолчанию',
            },
            helperMaxLines: 2,
            helperStyle: topics is AsyncError
                ? theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<String?>(child: Text('Без темы')),
            for (final topic in available)
              DropdownMenuItem<String?>(
                value: topic.id,
                child: Text(topic.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          // Until the directory arrives there is nothing to choose.
          onChanged: isBusy || available.isEmpty ? null : onTopicChanged,
        ),
      ],
    );
  }
}
