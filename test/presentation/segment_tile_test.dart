import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/theme/app_theme.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_tile.dart';

void main() {
  const segment = Segment(
    index: 0,
    text: 'Hello, how are you doing?',
    startMs: 0,
    endMs: 3000,
  );

  /// Плитка с записью того, куда ушёл тап.
  Future<List<String>> pumpTile(
    WidgetTester tester, {
    required bool isSelecting,
    bool isSelected = false,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SegmentTile(
            segment: segment,
            isActive: false,
            isPlaying: false,
            isLooped: false,
            isSelecting: isSelecting,
            isSelected: isSelected,
            isFocused: false,
            onPlayPressed: () => taps.add('play'),
            onLoopPressed: () => taps.add('loop'),
            onSelectPressed: () => taps.add('select'),
            onPressed: () => taps.add('focus'),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('вне режима выбора галочки перед текстом нет', (tester) async {
    final taps = await pumpTile(tester, isSelecting: false);

    expect(find.byType(Checkbox), findsNothing);
    // Тумблеры куска на месте: режим выбора их не заменяет.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);

    // Тап по тексту переводит фокус, а не набирает выделение.
    await tester.tap(find.text(segment.text));
    expect(taps, ['focus']);
  });

  testWidgets('в режиме выбора тап по плитке набирает выделение', (
    tester,
  ) async {
    final taps = await pumpTile(tester, isSelecting: true);

    expect(find.byType(Checkbox), findsOneWidget);

    await tester.tap(find.text(segment.text));
    expect(taps, ['select']);

    // И сама галочка ведёт туда же.
    await tester.tap(find.byType(Checkbox));
    expect(taps, ['select', 'select']);
  });

  testWidgets('галочка показывает, выбран ли кусок', (tester) async {
    await pumpTile(tester, isSelecting: true, isSelected: true);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
