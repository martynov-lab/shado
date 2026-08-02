import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/settings_mobile_view.dart';
import '../widgets/settings_tablet_view.dart';

/// Экран настроек: профиль, оформление, воспроизведение, обучение, язык и
/// хранилище.
///
/// Каркас (Scaffold, навигация) даёт [MainShell]. Реально работает только выбор
/// темы; остальные контролы — визуальные заготовки, привязку к настройкам
/// добавим отдельной задачей. Уровень пользователя пока подставляем макетным.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String routePath = '/settings';

  /// Placeholder до появления реальных данных профиля.
  static const String _placeholderLevel = 'B1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(
      authControllerProvider.select((state) => state.user?.email ?? ''),
    );
    final name = _displayName(email);

    return AppAdaptiveLayout(
      mobile: (context) => SettingsMobileView(
        name: name,
        email: email,
        level: _placeholderLevel,
      ),
      tablet: (context) => SettingsTabletView(
        name: name,
        email: email,
        level: _placeholderLevel,
      ),
    );
  }

  /// Имя для карточки профиля — часть почты до «@» с заглавной буквы.
  static String _displayName(String email) {
    if (email.isEmpty) return 'Профиль';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Профиль';
    return local[0].toUpperCase() + local.substring(1);
  }
}
