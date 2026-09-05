import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../progress/presentation/controllers/progress_providers.dart';
import '../../../settings/presentation/controllers/completion_reps_controller.dart';
import '../../../settings/presentation/widgets/settings_row.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../../settings/presentation/widgets/settings_text_edit_sheet.dart';
import '../../../settings/presentation/widgets/settings_value.dart';

/// The completion threshold block: how many repeats per segment mark a
/// lesson as done.
class CompletionThresholdSection extends ConsumerWidget {
  const CompletionThresholdSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reps = ref.watch(completionRepsProvider).value;

    return SettingsSection(
      title: 'Порог пройденности',
      rows: [
        SettingsRow(
          icon: Icons.repeat_rounded,
          title: 'Повторов на сегмент',
          subtitle: 'Сколько раз повторить сегмент, чтобы урок был пройден',
          trailing: SettingsValue(label: reps == null ? '…' : '$reps'),
          onTap: reps == null ? null : () => _edit(context, ref, reps),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, int current) async {
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: 'Порог пройденности',
      builder: (_) => SettingsTextEditSheet(
        label: 'Повторов на сегмент',
        initialValue: '$current',
        hint: 'Например, 10',
        keyboardType: TextInputType.number,
      ),
    );
    if (raw == null || !context.mounted) return;
    final reps = int.tryParse(raw.trim());
    if (reps == null) {
      _showMessage(context, 'Введите число повторов');
      return;
    }
    final error = await ref
        .read(completionRepsControllerProvider.notifier)
        .save(reps);
    if (error != null && context.mounted) _showMessage(context, error);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
