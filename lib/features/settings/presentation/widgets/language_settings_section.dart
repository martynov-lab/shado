import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/studied_language.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_value.dart';
import 'studied_language_sheet.dart';

/// Раздел «Язык»: изучаемый язык (редактируется) плюс язык интерфейса и
/// перевода.
///
/// Интерфейс и перевод пока заглушки из макета — их привязку добавим отдельной
/// задачей.
class LanguageSettingsSection extends ConsumerWidget {
  const LanguageSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(
      authControllerProvider.select((state) => state.user?.studiedLanguage),
    );

    return SettingsSection(
      title: 'Язык',
      rows: [
        SettingsRow(
          icon: Icons.school_outlined,
          title: 'Изучаемый язык',
          trailing: SettingsValue(label: studiedLanguageLabel(code)),
          onTap: () => _editLanguage(context, ref, code),
        ),
        const SettingsRow(
          icon: Icons.language_rounded,
          title: 'Язык интерфейса',
          trailing: SettingsValue(label: 'Русский'),
        ),
        const SettingsRow(
          icon: Icons.translate_rounded,
          title: 'Язык перевода',
          trailing: SettingsValue(label: 'Русский'),
        ),
      ],
    );
  }

  Future<void> _editLanguage(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final code = await showAppBottomSheet<String>(
      context: context,
      title: 'Изучаемый язык',
      builder: (_) => StudiedLanguageSheet(selectedCode: current),
    );
    if (code == null || !context.mounted) return;
    final error = await ref
        .read(settingsControllerProvider.notifier)
        .save(studiedLanguage: code);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
