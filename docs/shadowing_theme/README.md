# Shadowing — Design System

Токены, тема и стартовый виджет, собранные из style passport. Кастомная тема
поверх `MaterialApp`, две палитры (светлая/тёмная), адаптивность.

## Что внутри

```
lib/
  theme/
    theme.dart              // баррел — импортируй только его
    app_theme.dart          // AppTheme.light() / AppTheme.dark()
    context_ext.dart        // context.colors / context.shadows / responsive
    tokens/
      app_colors.dart       // ThemeExtension: все цвета, light + dark
      app_shadows.dart      // ThemeExtension: e1/e2/e3
      app_typography.dart   // AppText: шкала стилей
      app_dimens.dart       // AppSpacing / AppRadii / AppBreakpoints
      app_motion.dart       // AppDurations / AppCurves
  widgets/
    app_button.dart         // эталонный компонент — образец для остальных
```

## Шаги внедрения

### 1. Скопировать файлы
Перенеси папки `lib/theme/` и `lib/widgets/` в свой проект (в `lib/`).

### 2. Подключить шрифты (для локального приложения — бандлом)
Скачай с Google Fonts (лицензия OFL, можно класть в репозиторий):
Sora, Plus Jakarta Sans, JetBrains Mono. Положи `.ttf` в `assets/fonts/` и
добавь в `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Sora
      fonts:
        - asset: assets/fonts/Sora-Regular.ttf
        - asset: assets/fonts/Sora-Medium.ttf
          weight: 500
        - asset: assets/fonts/Sora-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Sora-Bold.ttf
          weight: 700
        - asset: assets/fonts/Sora-ExtraBold.ttf
          weight: 800
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
```

Имена в `family:` уже совпадают с константами в `app_typography.dart`.

> Быстрый старт без файлов: можно вместо бандла подключить пакет `google_fonts`.
> Но для полностью офлайн-приложения бандл надёжнее — шрифты не тянутся из сети.

### 3. Подключить тему в MaterialApp

```dart
import 'package:flutter/material.dart';
import 'theme/theme.dart';

MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system, // или свой стейт для ручного переключения
  home: const HomeScreen(),
);
```

### 4. Использовать токены

```dart
import 'theme/theme.dart';
import 'widgets/app_button.dart';

Container(
  padding: const EdgeInsets.all(AppSpacing.s6),
  decoration: BoxDecoration(
    color: context.colors.surface,
    borderRadius: AppRadii.rXl,
    boxShadow: context.shadows.e1,
  ),
  child: Column(children: [
    Text('Слушай. Повторяй.', style: Theme.of(context).textTheme.displayLarge),
    const SizedBox(height: AppSpacing.s4),
    AppButton(
      label: 'Слушать',
      icon: Icons.play_arrow_rounded,
      onPressed: () {},
    ),
  ]),
);

// адаптивность
final columns = context.responsive(mobile: 1, tablet: 2, desktop: 3);
```

## Требования
Flutter 3.27+ (используется `Color.withValues`). Если версия старше —
замени в `app_button.dart` `withValues(alpha: x)` на `withOpacity(x)`.

## Дальше
`app_button.dart` — образец паттерна (цвета из `context.colors`, размеры из
`AppSpacing`/`AppRadii`, текст из `AppText`). По этому шаблону строится
остальная библиотека: карточки, чипы, поля, строки списка и плеер с волной.
