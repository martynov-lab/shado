import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

void main() {
  Future<List<int>> pump(WidgetTester tester, {required int value}) async {
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppStarRating(value: value, onChanged: changes.add),
        ),
      ),
    );
    return changes;
  }

  testWidgets('shows as many filled stars as the value', (tester) async {
    await pump(tester, value: 3);

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
  });

  testWidgets('a tap on a star sets that rating', (tester) async {
    final changes = await pump(tester, value: 1);

    await tester.tap(find.bySemanticsLabel('4 of 5'));

    expect(changes, [4]);
  });

  testWidgets('a tap on the current rating clears it', (tester) async {
    final changes = await pump(tester, value: 4);

    await tester.tap(find.bySemanticsLabel('4 of 5'));

    expect(changes, [0]);
  });
}
