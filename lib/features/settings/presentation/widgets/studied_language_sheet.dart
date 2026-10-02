import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';

import '../../../languages/domain/entities/language.dart';
import 'studied_language_row.dart';

/// Studied language picker sheet; returns the selected code.
class StudiedLanguageSheet extends StatelessWidget {
  const StudiedLanguageSheet({
    super.key,
    required this.languages,
    required this.selectedCode,
  });

  final AsyncState<List<Language>> languages;

  /// Current code; the matching item is highlighted.
  final String? selectedCode;

  @override
  Widget build(BuildContext context) {
    return switch (languages) {
      AsyncReady(:final value) when value.isNotEmpty => Column(
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
      AsyncFailed() => Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Text(
          'The language list failed to load — check your connection and try again',
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
