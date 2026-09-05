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

    testWidgets('каждая иконка набора рисуется из своего ассета', (
      tester,
    ) async {
      await pumpIcons(tester, [
        for (final icon in AppIcons.values) AppIcon(icon),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.byType(AppIcon), findsNWidgets(AppIcons.values.length));
    });

    testWidgets('обычная иконка красится, фирменная остаётся своей', (
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

    testWidgets('без подписи иконка скрыта от скринридера', (tester) async {
      await pumpIcons(tester, const [
        AppIcon(AppIcons.bell),
        AppIcon(AppIcons.trash, semanticLabel: 'Удалить'),
      ]);

      final pictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(pictures.first.excludeFromSemantics, isTrue);
      expect(pictures.last.semanticsLabel, 'Удалить');
    });
  });

  group('$AppIcons', () {
    test('имена в коде совпадают с файлами набора', () {
      final files = Directory('assets/app_icons')
          .listSync()
          .whereType<File>()
          .map((file) => p.basenameWithoutExtension(file.path))
          .toSet();

      expect({for (final icon in AppIcons.values) icon.fileName}, files);
    });
  });
}
