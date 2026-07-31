import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lesson_category.dart';

/// Акцент, уровень и тема — по ним потом фильтруется каталог.
///
/// Акцент и уровень зашиты в клиенте: это закрытые списки, сервер меняет их
/// только релизом. Темы, наоборот, справочник — их правит владелец, поэтому
/// список приходит с сервера и может не загрузиться.
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

  /// Выбранные значения; `null` — поле ещё не заполняли.
  final LessonAccent? accent;
  final LessonLevel? level;

  /// Выбранная тема; `null` — «без темы».
  final String? topicId;

  /// Справочник тем с сервера: по нему же собирается подсказка под полем.
  final AsyncValue<List<Topic>> topics;

  /// Идёт отправка или загрузка файла — поля заперты.
  final bool isBusy;

  final ValueChanged<LessonAccent?> onAccentChanged;
  final ValueChanged<LessonLevel?> onLevelChanged;
  final ValueChanged<String?> onTopicChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = topics.value ?? const <Topic>[];
    // Список падает, если выбранного значения нет среди пунктов: тему могли
    // удалить на другом устройстве, пока заполняли форму.
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
                // Подписи вида «B1 — средний» в половину строки не влезают,
                // поэтому в закрытом поле остаётся только код уровня.
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
          // Пока справочник не пришёл, выбирать нечего.
          onChanged: isBusy || available.isEmpty ? null : onTopicChanged,
        ),
      ],
    );
  }
}
