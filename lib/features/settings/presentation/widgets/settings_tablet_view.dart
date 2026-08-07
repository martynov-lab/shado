import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'appearance_settings_section.dart';
import 'language_settings_section.dart';
import 'learning_settings_section.dart';
import 'playback_settings_section.dart';
import 'settings_profile_card.dart';
import 'storage_settings_section.dart';

/// Настройки на планшете и десктопе: профиль во всю ширину и разделы в две
/// колонки. Ширина ограничена [AppBreakpoints.maxContent], чтобы на широком
/// экране строки не растягивались.
///
/// Когда доступной ширины на две колонки не хватает (узкое окно, планшет с
/// рельсом), разделы идут одной колонкой — иначе контролы не помещаются в
/// узкую карточку.
class SettingsTabletView extends StatelessWidget {
  const SettingsTabletView({
    super.key,
    required this.name,
    required this.email,
    required this.onEditName,
    this.languageLabel,
  });

  final String name;
  final String email;
  final VoidCallback onEditName;

  /// Подпись изучаемого языка; `null` — бейдж скрыт.
  final String? languageLabel;

  static const double _twoColumnMinWidth = 720;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= _twoColumnMinWidth;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.s6),
                children: [
                  Text(
                    'Настройки',
                    style: AppText.h2.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  SettingsProfileCard(
                    name: name,
                    email: email,
                    languageLabel: languageLabel,
                    onEdit: onEditName,
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  if (twoColumns)
                    const _TwoColumnSections()
                  else
                    const _SingleColumnSections(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Разделы в две колонки: слева — оформление и воспроизведение, справа —
/// обучение, язык и хранилище.
class _TwoColumnSections extends StatelessWidget {
  const _TwoColumnSections();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              AppearanceSettingsSection(),
              SizedBox(height: AppSpacing.s4),
              PlaybackSettingsSection(),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Column(
            children: [
              LearningSettingsSection(),
              SizedBox(height: AppSpacing.s4),
              LanguageSettingsSection(),
              SizedBox(height: AppSpacing.s4),
              StorageSettingsSection(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Те же разделы одной колонкой — для узких окон.
class _SingleColumnSections extends StatelessWidget {
  const _SingleColumnSections();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppearanceSettingsSection(),
        SizedBox(height: AppSpacing.s4),
        PlaybackSettingsSection(),
        SizedBox(height: AppSpacing.s4),
        LearningSettingsSection(),
        SizedBox(height: AppSpacing.s4),
        LanguageSettingsSection(),
        SizedBox(height: AppSpacing.s4),
        StorageSettingsSection(),
      ],
    );
  }
}
