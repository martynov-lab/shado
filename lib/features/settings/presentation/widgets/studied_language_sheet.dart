import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';

import '../../../languages/domain/entities/language.dart';
import '../../../languages/presentation/controllers/language_providers.dart';
import 'studied_language_row.dart';

/// Studied language picker sheet; returns the selected code.
class StudiedLanguageSheet extends ConsumerWidget {
  const StudiedLanguageSheet({super.key, required this.selectedCode});

  /// Current code; the matching item is highlighted.
  final String? selectedCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(languagesProvider);

    return switch (languages) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final Language language in value)
            StudiedLanguageRow(
              label: language.label,
              note: language.nativeName == language.name
                  ? null
                  : language.nativeName,
              selected: language.code == selectedCode,
              onTap: () => Navigator.of(context).pop(language.code),
            ),
        ],
      ),
      AsyncError() => Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Text(
          'Список языков не загрузился — проверьте связь и попробуйте снова',
          style: AppText.body.copyWith(color: context.colors.text3),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.s6),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    };
  }
}
