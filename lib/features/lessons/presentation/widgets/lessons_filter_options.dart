import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson_category.dart';
import '../controllers/lesson_providers.dart';
import '../controllers/lessons_filter.dart';

/// Группа фильтров списка уроков.
enum LessonFilterGroup {
  topic('Тема'),
  level('Уровень'),
  status('Статус'),
  access('Доступ');

  const LessonFilterGroup(this.title);

  final String title;
}

/// Флажки фильтров: темы, уровни и статусы.
///
/// В модальном листе на телефоне/планшете показываем одну группу ([only]).
/// В боковой панели на десктопе — все три, каждая сворачивается и по умолчанию
/// свёрнута.
class LessonsFilterOptions extends StatelessWidget {
  const LessonsFilterOptions({super.key, this.only});

  /// `null` — показать все группы сворачиваемыми; иначе одну развёрнутую.
  final LessonFilterGroup? only;

  @override
  Widget build(BuildContext context) {
    if (only case final group?) return _optionsFor(group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final group in LessonFilterGroup.values)
          _CollapsibleGroup(title: group.title, child: _optionsFor(group)),
      ],
    );
  }

  Widget _optionsFor(LessonFilterGroup group) => switch (group) {
    LessonFilterGroup.topic => const _TopicOptions(),
    LessonFilterGroup.level => const _LevelOptions(),
    LessonFilterGroup.status => const _StatusOptions(),
    LessonFilterGroup.access => const _AccessOptions(),
  };
}

/// Сворачиваемая секция фильтра: заголовок с шевроном, содержимое скрыто по
/// умолчанию.
class _CollapsibleGroup extends StatefulWidget {
  const _CollapsibleGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_CollapsibleGroup> createState() => _CollapsibleGroupState();
}

class _CollapsibleGroupState extends State<_CollapsibleGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: widget.title,
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.rSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppText.label.copyWith(color: colors.text),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: context.motion(AppDurations.fast),
                      child: AppIcon(
                        AppIcons.chevronDown,
                        size: AppSizes.iconSm,
                        color: colors.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: widget.child,
          ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: AppCheckbox(
        value: selected,
        label: label,
        onChanged: (_) => onToggle(),
      ),
    );
  }
}

class _TopicOptions extends ConsumerWidget {
  const _TopicOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      lessonsFilterProvider.select((filter) => filter.topicIds),
    );
    final topics = ref.watch(topicsProvider);
    final notifier = ref.read(lessonsFilterProvider.notifier);

    return switch (topics) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final Topic topic in value)
            _OptionRow(
              label: topic.name,
              selected: selected.contains(topic.id),
              onToggle: () => notifier.toggleTopic(topic.id),
            ),
        ],
      ),
      AsyncError() => Text(
        'Темы недоступны',
        style: AppText.caption.copyWith(color: context.colors.text3),
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: AppSizes.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    };
  }
}

class _LevelOptions extends ConsumerWidget {
  const _LevelOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      lessonsFilterProvider.select((filter) => filter.levels),
    );
    final notifier = ref.read(lessonsFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final level in LessonLevel.values)
          _OptionRow(
            label: level.label,
            selected: selected.contains(level),
            onToggle: () => notifier.toggleLevel(level),
          ),
      ],
    );
  }
}

class _AccessOptions extends ConsumerWidget {
  const _AccessOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlyPrivate = ref.watch(
      lessonsFilterProvider.select((filter) => filter.onlyPrivate),
    );
    final notifier = ref.read(lessonsFilterProvider.notifier);

    // Сервер отдаёт приватными только свои уроки, поэтому у обычного
    // пользователя фильтр просто ничего не отберёт — это ожидаемо.
    return _OptionRow(
      label: 'Мои приватные',
      selected: onlyPrivate,
      onToggle: notifier.toggleOnlyPrivate,
    );
  }
}

class _StatusOptions extends ConsumerWidget {
  const _StatusOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      lessonsFilterProvider.select((filter) => filter.statuses),
    );
    final notifier = ref.read(lessonsFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final status in LessonFilterStatus.values)
          _OptionRow(
            label: status.label,
            selected: selected.contains(status),
            onToggle: () => notifier.toggleStatus(status),
          ),
      ],
    );
  }
}
