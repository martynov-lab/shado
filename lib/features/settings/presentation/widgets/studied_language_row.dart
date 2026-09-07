import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A language row of the studied language sheet.
class StudiedLanguageRow extends StatelessWidget {
  const StudiedLanguageRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String label;

  /// Native name under the label; `null` hides the second line.
  final String? note;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final note = this.note;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppText.body.copyWith(
                          color: selected ? colors.primary : colors.text,
                        ),
                      ),
                      if (note != null && note.isNotEmpty)
                        Text(
                          note,
                          style: AppText.caption.copyWith(color: colors.text3),
                        ),
                    ],
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
