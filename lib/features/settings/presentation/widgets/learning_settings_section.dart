import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_switch_row.dart';
import 'settings_text_edit_sheet.dart';
import 'settings_value.dart';

/// Раздел «Обучение»: дневная цель (редактируется) и напоминания.
///
/// Напоминания пока заглушка — их привязку добавим отдельной задачей.
class LearningSettingsSection extends ConsumerWidget {
  const LearningSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(
      authControllerProvider.select((state) => state.user?.dailyGoalMinutes),
    );

    return SettingsSection(
      title: 'Обучение',
      rows: [
        SettingsRow(
          icon: Icons.schedule_rounded,
          title: 'Дневная цель',
          trailing: SettingsValue(
            label: goal == null ? 'Не задана' : '$goal мин',
          ),
          onTap: () => _editGoal(context, ref, goal),
        ),
        const SettingsSwitchRow(
          icon: Icons.notifications_outlined,
          title: 'Напоминания',
          subtitle: 'Каждый день в 20:00',
          initialValue: true,
        ),
      ],
    );
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    int? current,
  ) async {
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: 'Дневная цель',
      builder: (_) => SettingsTextEditSheet(
        label: 'Минут в день',
        initialValue: current?.toString() ?? '',
        hint: 'Например, 15',
        keyboardType: TextInputType.number,
      ),
    );
    if (raw == null || !context.mounted) return;
    final trimmed = raw.trim();
    // Пустое поле — оставляем цель как была.
    if (trimmed.isEmpty) return;
    final minutes = int.tryParse(trimmed);
    if (minutes == null) {
      _showMessage(context, 'Введите число минут');
      return;
    }
    final error = await ref
        .read(settingsControllerProvider.notifier)
        .save(dailyGoalMinutes: minutes);
    if (error != null && context.mounted) _showMessage(context, error);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
