import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/studied_language.dart';
import '../widgets/settings_mobile_view.dart';
import '../widgets/settings_tablet_view.dart';
import '../widgets/settings_text_edit_sheet.dart';

/// Settings screen: profile, appearance, playback, learning, language and
/// storage.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((state) => state.user));
    final email = user?.email ?? '';
    final name = _displayName(user, email);
    final languageLabel = user?.studiedLanguage == null
        ? null
        : studiedLanguageLabel(user!.studiedLanguage);

    return AppAdaptiveLayout(
      mobile: (context) => SettingsMobileView(
        name: name,
        email: email,
        languageLabel: languageLabel,
        onEditName: () => _editName(context, ref, user?.name ?? ''),
      ),
      tablet: (context) => SettingsTabletView(
        name: name,
        email: email,
        languageLabel: languageLabel,
        onEditName: () => _editName(context, ref, user?.name ?? ''),
      ),
    );
  }

  /// Name for the profile card; without one, the email local part.
  static String _displayName(AuthUser? user, String email) {
    final name = user?.name;
    if (name != null && name.isNotEmpty) return name;
    if (email.isEmpty) return 'Профиль';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Профиль';
    return local[0].toUpperCase() + local.substring(1);
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: 'Имя',
      builder: (_) => SettingsTextEditSheet(
        label: 'Имя',
        initialValue: current,
        hint: 'Андрей',
      ),
    );
    if (raw == null || !context.mounted) return;
    final error = await ref
        .read(settingsControllerProvider.notifier)
        .save(name: raw.trim());
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
