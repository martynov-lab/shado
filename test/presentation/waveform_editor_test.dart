import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/theme/app_theme.dart';
import 'package:shado/features/lessons/data/models/waveform_peaks.dart';
import 'package:shado/features/lessons/presentation/widgets/waveform_editor.dart';

void main() {
  const durationMs = 9000;
  const width = 400.0;
  const height = 160.0;

  /// Ровная волна: для проверки жестов форма пиков не важна.
  final peaks = WaveformPeaks(
    minima: List<double>.filled(100, -0.5),
    maxima: List<double>.filled(100, 0.5),
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    required List<int> boundaries,
    ValueChanged<List<int>>? onBoundariesChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: WaveformEditor(
              peaks: peaks,
              durationMs: durationMs,
              boundaries: boundaries,
              positionMs: 0,
              height: height,
              onBoundariesChanged: onBoundariesChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('перетаскивание метки отдаёт новые границы', (tester) async {
    List<int>? reported;
    await pumpEditor(
      tester,
      boundaries: const [0, 3000, 6000, 9000],
      onBoundariesChanged: (value) => reported = value,
    );

    // Метка 3000 мс стоит на x = 3000 / 9000 * 400.
    await tester.dragFrom(const Offset(133, 80), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(reported, isNotNull);
    expect(reported!.first, 0);
    expect(reported!.last, durationMs);
    expect(reported![2], 6000);
    // 233 / 400 * 9000 ≈ 5243.
    expect(reported![1], closeTo(5243, 60));
  });

  testWidgets('крайние метки не двигаются', (tester) async {
    List<int>? reported;
    await pumpEditor(
      tester,
      boundaries: const [0, 4500, 9000],
      onBoundariesChanged: (value) => reported = value,
    );

    // Тянем от самого края: там только неподвижная граница 0.
    await tester.dragFrom(const Offset(2, 80), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(reported, isNull);
  });

  testWidgets('кнопки меняют масштаб и сбрасывают его', (tester) async {
    await pumpEditor(tester, boundaries: const [0, 3000, 6000, 9000]);

    expect(find.text('1.0×'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('1.6×'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('2.6×'), findsOneWidget);

    // Клик по подписи возвращает волну к исходному масштабу.
    await tester.tap(find.text('2.6×'));
    await tester.pumpAndSettle();
    expect(find.text('1.0×'), findsOneWidget);
  });

  testWidgets('на растянутой волне метка ставится точнее', (tester) async {
    List<int>? reported;
    await pumpEditor(
      tester,
      boundaries: const [0, 4500, 9000],
      onBoundariesChanged: (value) => reported = value,
    );

    // Кнопки тянут масштаб к середине окна, поэтому метка 4500 мс остаётся
    // ровно посередине — на x = 200.
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('4.1×'), findsOneWidget);

    await tester.dragFrom(const Offset(200, 80), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(reported, isNotNull);
    // Те же 40 пикселей на 4× стоят вчетверо меньше времени: ~220 мс вместо
    // 900 на исходном масштабе.
    expect(reported![1] - 4500, closeTo(220, 60));
  });
}
