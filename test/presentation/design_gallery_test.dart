import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/screens/design_gallery/design_gallery_screen.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpGallery(
    WidgetTester tester, {
    required ThemeMode mode,
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The gallery calls `context.canPop()`, so it gets a minimal GoRouter.
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DesignGalleryScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Types that must appear while scrolling the whole gallery.
  const expected = <Type>[
    AppButton,
    AppIcon,
    AppIconButton,
    AppTextField,
    AppDropdown<String>,
    AppSlider,
    AppCheckbox,
    AppSwitch,
    AppSegmentedControl<ThemeMode>,
    AppChip,
    AppFilterChip,
    AppBadge,
    AppCard,
    AppListRow,
    ThemeToggle,
  ];

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final size in const [
      Size(390, 900),
      Size(800, 1200),
      Size(1400, 1000),
    ]) {
      testWidgets('the gallery renders: $mode, width ${size.width}', (
        tester,
      ) async {
        await pumpGallery(tester, mode: mode, size: size);

        final seen = <Type>{};
        final scrollable = find.byType(Scrollable).first;
        for (var step = 0; step < 40; step++) {
          for (final type in expected) {
            if (find.byType(type).evaluate().isNotEmpty) seen.add(type);
          }
          expect(tester.takeException(), isNull, reason: 'scroll step $step');
          await tester.drag(scrollable, const Offset(0, -300));
          await tester.pump();
        }

        expect(seen, containsAll(expected));
      });
    }
  }

  testWidgets('the modal sheet and the snackbar open', (tester) async {
    await pumpGallery(
      tester,
      mode: ThemeMode.dark,
      size: const Size(800, 1200),
    );

    await tester.dragUntilVisible(
      find.text('Modal sheet'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    // dragUntilVisible stops on a built but still invisible widget.
    await tester.ensureVisible(find.text('Modal sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modal sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Playback speed'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Success'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the theme choice survives a restart', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final first = await ThemeController.restored();
    expect(first.value, ThemeMode.system);

    await first.setMode(ThemeMode.dark);

    final reopened = await ThemeController.restored();
    expect(reopened.value, ThemeMode.dark);
  });

  testWidgets('ThemeToggle switches the app theme', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final controller = ref.watch(themeControllerProvider);
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: controller,
              builder: (context, mode, _) => MaterialApp(
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: mode,
                home: const Scaffold(body: Center(child: ThemeToggle())),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ThemeToggle));
    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(ThemeToggle))).brightness,
      Brightness.light,
    );
  });
}
