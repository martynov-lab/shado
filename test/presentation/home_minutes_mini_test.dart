import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/home/presentation/widgets/home_minutes_mini.dart';
import 'package:shado/theme/theme.dart';

void main() {
  testWidgets('мини-график минут показывает подписи дней недели', (
    tester,
  ) async {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 272,
              child: HomeMinutesMini(
                values: [0, 40, 0, 100, 0, 0, 60],
                labels: labels,
                todayIndex: 6,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
