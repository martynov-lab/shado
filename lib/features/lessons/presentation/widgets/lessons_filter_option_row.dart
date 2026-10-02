import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// One checkbox of a filter group.
class LessonsFilterOptionRow extends StatelessWidget {
  const LessonsFilterOptionRow({
    super.key,
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
