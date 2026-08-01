import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/presentation/widgets/lesson_segment_row.dart';
import 'package:shado/theme/app_theme.dart';
import 'package:shado/widgets/app_checkbox.dart';

void main() {
  const segment = Segment(
    index: 0,
    text: 'Hello, how are you doing?',
    startMs: 0,
    endMs: 3000,
  );

  /// Строка с записью того, куда ушёл тап.
  Future<List<String>> pumpRow(
    WidgetTester tester, {
    required bool isSelecting,
    bool isSelected = false,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LessonSegmentRow(
            segment: segment,
            isCurrent: false,
            isPlaying: false,
            isSelecting: isSelecting,
            isSelected: isSelected,
            onPressed: () => taps.add('current'),
            onSelectPressed: () => taps.add('select'),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('вне режима выбора галочки нет, тап делает сегмент текущим', (
    tester,
  ) async {
    final taps = await pumpRow(tester, isSelecting: false);

    expect(find.byType(AppCheckbox), findsNothing);

    await tester.tap(find.text(segment.text));
    expect(taps, ['current']);
  });

  testWidgets('в режиме выбора тап по строке набирает выделение', (
    tester,
  ) async {
    final taps = await pumpRow(tester, isSelecting: true);

    expect(find.byType(AppCheckbox), findsOneWidget);

    await tester.tap(find.text(segment.text));
    expect(taps, ['select']);

    // И сама галочка ведёт туда же.
    await tester.tap(find.byType(AppCheckbox));
    expect(taps, ['select', 'select']);
  });

  testWidgets('галочка показывает, выбран ли сегмент', (tester) async {
    await pumpRow(tester, isSelecting: true, isSelected: true);
    expect(
      tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value,
      isTrue,
    );
  });
}
