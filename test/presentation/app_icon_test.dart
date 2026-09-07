import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

void main() {
  group('$AppIcon', () {
    /// The icon set inside the app theme, as any screen draws it.
    Future<void> pumpIcons(WidgetTester tester, List<Widget> icons) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: Wrap(children: icons)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('every icon of the set is drawn from its own asset', (
      tester,
    ) async {
      await pumpIcons(tester, [
        for (final icon in AppIcons.values) AppIcon(icon),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.byType(AppIcon), findsNWidgets(AppIcons.values.length));
    });

    testWidgets('a plain icon is tinted while a branded one keeps its colors', (
      tester,
    ) async {
      await pumpIcons(tester, const [
        AppIcon(AppIcons.play, color: Color(0xFF00FF00)),
        AppIcon(AppIcons.brandGoogle, color: Color(0xFF00FF00)),
      ]);

      final pictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(
        pictures.first.colorFilter,
        const ColorFilter.mode(Color(0xFF00FF00), BlendMode.srcIn),
      );
      expect(pictures.last.colorFilter, isNull);
    });

    testWidgets('without a label the icon is hidden from the screen reader', (tester) async {
      await pumpIcons(tester, const [
        AppIcon(AppIcons.bell),
        AppIcon(AppIcons.trash, semanticLabel: 'Delete'),
      ]);

      final pictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(pictures.first.excludeFromSemantics, isTrue);
      expect(pictures.last.semanticsLabel, 'Delete');
    });
  });

  group('$AppIcons', () {
    test('the names in code match the files of the set', () {
      final files = Directory('assets/app_icons')
          .listSync()
          .whereType<File>()
          .map((file) => p.basenameWithoutExtension(file.path))
          .toSet();

      expect({for (final icon in AppIcons.values) icon.fileName}, files);
    });
  });
}
