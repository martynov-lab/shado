import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/router/app_router.dart';
import 'package:shado/features/progress/presentation/controllers/progress_providers.dart';
import 'package:shado/theme/theme.dart';

class ShadoApp extends ConsumerStatefulWidget {
  const ShadoApp({super.key});

  @override
  ConsumerState<ShadoApp> createState() => _ShadoAppState();
}

class _ShadoAppState extends ConsumerState<ShadoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Системный «уменьшить движение» может переключиться на ходу — тогда
  /// пересобираем, чтобы подхватить нулевую длительность.
  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  /// Уходя в фон, досылаем накопленный прогресс: приложение могут закрыть, не
  /// вернувшись на экран урока.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(progressReporterProvider).flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(themeControllerProvider);
    // MediaQuery здесь ещё нет — он появляется внутри MaterialApp, а
    // длительность нужна самому MaterialApp. Берём тот же флаг из платформы.
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'Shado',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        themeAnimationDuration: reduceMotion
            ? Duration.zero
            : AppDurations.slow,
        themeAnimationCurve: AppCurves.standard,
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
