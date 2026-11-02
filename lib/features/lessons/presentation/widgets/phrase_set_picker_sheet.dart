import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Where a phrase from a story goes: one of the user's sets or a new one.
/// Returns the set id, or [newSet] for a new set.
class PhraseSetPickerSheet extends StatelessWidget {
  const PhraseSetPickerSheet({super.key, required this.sets});

  /// What the sheet returns for a new set.
  static const String newSet = '';

  /// Sets the phrase may go to: `(id, title)`.
  final List<(String, String)> sets;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.add_rounded, color: colors.primary),
          title: Text(
            'New set',
            style: AppText.label.copyWith(color: colors.primary),
          ),
          onTap: () => Navigator.of(context).pop(newSet),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final (id, title) in sets)
                ListTile(
                  leading: Icon(Icons.format_quote_rounded, color: colors.text3),
                  title: Text(
                    title,
                    style: AppText.label.copyWith(color: colors.text),
                  ),
                  onTap: () => Navigator.of(context).pop(id),
                ),
            ],
          ),
        ),
        if (sets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Text(
              'No phrase sets yet — the phrase starts a new one.',
              style: AppText.caption.copyWith(color: colors.text3),
            ),
          ),
      ],
    );
  }
}
