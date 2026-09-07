import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../languages/presentation/controllers/language_providers.dart';
import '../controllers/studied_language_controller.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_value.dart';
import 'studied_language_sheet.dart';
import 'switch_language_dialog.dart';

/// Language section: studied, interface and translation languages.
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
          trailing: SettingsValue(
            label: ref.watch(studiedLanguageLabelProvider),
          ),
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

  /// Picks a language, warns about the catalog and switches it.
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
    if (code == null || code == current || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => SwitchLanguageDialog(languageLabel: _labelFor(ref, code)),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(studiedLanguageControllerProvider.notifier)
        .change(code);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// Language name from the directory; an unknown code is shown as is.
  String _labelFor(WidgetRef ref, String code) {
    final languages = ref.read(languagesProvider).value ?? const [];
    for (final language in languages) {
      if (language.code == code) return language.label;
    }
    return code;
  }
}
