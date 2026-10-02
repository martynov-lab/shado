import 'package:flutter/material.dart';

import '../../../settings/presentation/widgets/settings_row.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../../settings/presentation/widgets/settings_value.dart';

/// The completion threshold block: how many repeats per segment mark a
/// lesson as done.
class CompletionThresholdSection extends StatelessWidget {
  const CompletionThresholdSection({
    super.key,
    required this.reps,
    required this.onEdit,
  });

  /// `null` while the threshold loads; the row is not tappable then.
  final int? reps;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final reps = this.reps;

    return SettingsSection(
      title: 'Completion threshold',
      rows: [
        SettingsRow(
          icon: Icons.repeat_rounded,
          title: 'Repeats per segment',
          subtitle: 'How many times to repeat a segment to complete the lesson',
          trailing: SettingsValue(label: reps == null ? '…' : '$reps'),
          onTap: reps == null ? null : onEdit,
        ),
      ],
    );
  }
}
