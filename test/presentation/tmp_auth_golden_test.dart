import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/auth/presentation/pages/login_page.dart';
import 'package:shado/theme/theme.dart';

Future<void> _loadFonts() async {
  const families = {
    'Sora': [
      'assets/fonts/Sora-Regular.ttf',
      'assets/fonts/Sora-SemiBold.ttf',
      'assets/fonts/Sora-Bold.ttf',
      'assets/fonts/Sora-ExtraBold.ttf',
    ],
    'PlusJakartaSans': [
      'assets/fonts/PlusJakartaSans-Regular.ttf',
      'assets/fonts/PlusJakartaSans-Medium.ttf',
      'assets/fonts/PlusJakartaSans-SemiBold.ttf',
      'assets/fonts/PlusJakartaSans-Bold.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final bytes = await File(path).readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

void main() {
  Future<void> shoot(
    WidgetTester tester, {
    required Size size,
    required ThemeMode mode,
    required bool isRegistration,
    required String name,
  }) async {
    await _loadFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: LoginPage(isRegistration: isRegistration),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('mobile dark login', (tester) async {
    await shoot(
      tester,
      size: const Size(390, 860),
      mode: ThemeMode.dark,
      isRegistration: false,
      name: 'mobile_dark_login',
    );
  });

  testWidgets('mobile light register', (tester) async {
    await shoot(
      tester,
      size: const Size(390, 900),
      mode: ThemeMode.light,
      isRegistration: true,
      name: 'mobile_light_register',
    );
  });

  testWidgets('tablet dark login', (tester) async {
    await shoot(
      tester,
      size: const Size(760, 900),
      mode: ThemeMode.dark,
      isRegistration: false,
      name: 'tablet_dark_login',
    );
  });

  testWidgets('desktop dark login', (tester) async {
    await shoot(
      tester,
      size: const Size(1180, 700),
      mode: ThemeMode.dark,
      isRegistration: false,
      name: 'desktop_dark_login',
    );
  });
}
