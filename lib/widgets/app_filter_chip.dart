import 'package:flutter/material.dart';

import 'package:shado/widgets/app_chip.dart';

/// Toggleable filter chip; shows a check mark when selected.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.style = AppChipStyle.onSoft,
    this.semanticLabel,
  });

  final String label;
  final bool selected;

  /// `null` disables the filter.
  final ValueChanged<bool>? onSelected;

  /// Icon for the unselected state.
  final IconData? icon;

  final AppChipStyle style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      selected: selected,
      style: style,
      icon: selected ? Icons.check_rounded : icon,
      semanticLabel: semanticLabel,
      onTap: onSelected == null ? null : () => onSelected!(!selected),
    );
  }
}
