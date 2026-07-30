import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Выбранная тема: светлая, тёмная или «как в системе».
///
/// Хранится локально — приложение работает офлайн, и выбор обязан пережить
/// перезапуск. Значение отдаётся как [ValueListenable], поэтому подписчику
/// (обычно `MaterialApp`) не нужен ни стрим, ни кодогенерация.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({ThemeMode initial = ThemeMode.system}) : super(initial);

  /// Создаёт контроллер и дожидается чтения сохранённого выбора — так на
  /// первом кадре не мелькает не та тема.
  static Future<ThemeController> restored() async {
    final controller = ThemeController();
    await controller.restore();
    return controller;
  }

  @visibleForTesting
  static const String storageKey = 'theme_mode';

  bool _disposed = false;

  /// Читает сохранённый режим. Ошибку хранилища гасим: не суметь прочитать
  /// настройку оформления — не повод не запустить приложение.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(storageKey);
      if (stored == null || _disposed) return;
      value = ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );
    } on Exception {
      // Остаёмся на ThemeMode.system.
    }
  }

  /// Меняет тему и сохраняет выбор.
  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, mode.name);
    } on Exception {
      // Тема уже переключена — запись просто не переживёт перезапуск.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Контроллер темы приложения.
///
/// В `main()` его подменяют уже восстановленным экземпляром
/// ([ThemeController.restored]); значение по умолчанию восстанавливается само,
/// чтобы виджет-тесты работали без подмены.
final themeControllerProvider = Provider<ThemeController>((ref) {
  final controller = ThemeController();
  unawaited(controller.restore());
  ref.onDispose(controller.dispose);
  return controller;
});
