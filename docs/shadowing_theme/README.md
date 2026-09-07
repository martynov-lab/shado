# Shadowing — Design System

Tokens, the theme and a starter widget, assembled from the style passport. A
custom theme on top of `MaterialApp`, two palettes (light and dark), and
adaptivity.

## What is inside

```
lib/
  theme/
    theme.dart              // barrel — import only this
    app_theme.dart          // AppTheme.light() / AppTheme.dark()
    context_ext.dart        // context.colors / context.shadows / responsive
    tokens/
      app_colors.dart       // ThemeExtension: every color, light and dark
      app_shadows.dart      // ThemeExtension: e1/e2/e3
      app_typography.dart   // AppText: the style scale
      app_dimens.dart       // AppSpacing / AppRadii / AppBreakpoints
      app_motion.dart       // AppDurations / AppCurves
  widgets/
    app_button.dart         // the reference component, a model for the rest
```

## Adoption steps

### 1. Copy the files
Move the `lib/theme/` and `lib/widgets/` folders into your project (under
`lib/`).

### 2. Wire up the fonts (bundled, for a local app)
Download them from Google Fonts (the OFL license allows keeping them in the
repository): Sora, Plus Jakarta Sans, JetBrains Mono. Put the `.ttf` files into
`assets/fonts/` and add them to `pubspec.yaml`:

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

The names in `family:` already match the constants in `app_typography.dart`.

> A quick start without the files: the `google_fonts` package can be used
> instead of bundling. For a fully offline app, though, bundling is more
> reliable — the fonts are not pulled over the network.

### 3. Wire the theme into MaterialApp

```dart
import 'package:flutter/material.dart';
import 'theme/theme.dart';

MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system, // or your own state for manual switching
  home: const HomeScreen(),
);
```

### 4. Use the tokens

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

// adaptive layout
final columns = context.responsive(mobile: 1, tablet: 2, desktop: 3);
```

## Requirements
Flutter 3.27+ (it uses `Color.withValues`). On an older version, replace
`withValues(alpha: x)` with `withOpacity(x)` in `app_button.dart`.

## What comes next
`app_button.dart` is the pattern to follow (colors from `context.colors`, sizes
from `AppSpacing`/`AppRadii`, text from `AppText`). The rest of the library is
built on that template: cards, chips, fields, list rows and the player with the
waveform.
