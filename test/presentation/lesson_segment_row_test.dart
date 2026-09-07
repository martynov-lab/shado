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

  /// A line recording where the tap went.
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

  testWidgets('outside selection mode there is no checkbox and a tap makes the segment current', (
    tester,
  ) async {
    final taps = await pumpRow(tester, isSelecting: false);

    expect(find.byType(AppCheckbox), findsNothing);

    await tester.tap(find.text(segment.text));
    expect(taps, ['current']);
  });

  testWidgets('in selection mode a tap on the row builds up the selection', (
    tester,
  ) async {
    final taps = await pumpRow(tester, isSelecting: true);

    expect(find.byType(AppCheckbox), findsOneWidget);

    await tester.tap(find.text(segment.text));
    expect(taps, ['select']);

    // The checkbox itself leads to the same place.
    await tester.tap(find.byType(AppCheckbox));
    expect(taps, ['select', 'select']);
  });

  testWidgets('the checkbox shows whether the segment is selected', (tester) async {
    await pumpRow(tester, isSelecting: true, isSelected: true);
    expect(
      tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value,
      isTrue,
    );
  });
}
