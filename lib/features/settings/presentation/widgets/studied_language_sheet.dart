import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/studied_language.dart';

/// Studied language picker sheet; returns the selected code.
class StudiedLanguageSheet extends StatelessWidget {
  const StudiedLanguageSheet({super.key, required this.selectedCode});

  /// Current code; the matching item is highlighted.
  final String? selectedCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final language in StudiedLanguage.values)
          _LanguageRow(
            label: language.label,
            selected: language.code == selectedCode,
            onTap: () => Navigator.of(context).pop(language.code),
          ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s3,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.body.copyWith(
                      color: selected ? colors.primary : colors.text,
                    ),
                  ),
                ),
                if (selected)
                  AppIcon(
                    AppIcons.check,
                    size: AppSizes.iconMd,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
