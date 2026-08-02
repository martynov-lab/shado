import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../lessons/presentation/pages/lessons_page.dart';
import '../widgets/home_desktop_view.dart';
import '../widgets/home_mobile_view.dart';
import '../widgets/home_tablet_view.dart';

/// Главная — раздел «Главная»: приветствие, карточка «Продолжить», статистика,
/// цель недели и превью «Мои уроки».
///
/// Каркас (Scaffold, фон, навигация) даёт [MainShell]; раскладку выбирает
/// [AppAdaptiveLayout]. Данные пока демонстрационные — реальные метрики
/// подключим отдельной задачей.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(
      authControllerProvider.select((state) => state.user?.email ?? ''),
    );
    final name = _greetingName(email);
    void openLessons() => context.go(LessonsPage.routePath);

    return AppAdaptiveLayout(
      mobile: (context) => HomeMobileView(name: name, onOpenLessons: openLessons),
      tablet: (context) => HomeTabletView(name: name, onOpenLessons: openLessons),
      desktop: (context) =>
          HomeDesktopView(name: name, onOpenLessons: openLessons),
    );
  }
}

/// Имя для приветствия из почты: часть до «@» с заглавной буквы. Пусто — «друг».
String _greetingName(String email) {
  final local = email.split('@').first.trim();
  if (local.isEmpty) return 'друг';
  return local[0].toUpperCase() + local.substring(1);
}
