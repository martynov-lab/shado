import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/marked_text_controller.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_marker.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_splitter_field.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Splitter field: placing and removing markers through the widget.
void main() {
  Widget wrap({
    required MarkedTextController controller,
    required int segmentCount,
    ValueChanged<String>? onChanged,
    void Function(String text, int ordinal)? onMarkerInserted,
    ValueChanged<int>? onMarkerRemoved,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: SegmentSplitterField(
              controller: controller,
              segmentCount: segmentCount,
              onChanged: onChanged ?? (_) {},
              onMarkerInserted: onMarkerInserted ?? (_, _) {},
              onMarkerRemoved: onMarkerRemoved ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the marker chip and the segment count', (tester) async {
    final controller = MarkedTextController(text: 'one | two | three');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 3));
    await tester.pumpAndSettle();

    expect(find.byType(SegmentMarkerChip), findsOneWidget);
    expect(find.text('Сегментов: 3'), findsOneWidget);
  });

  testWidgets('the reset button removes every marker', (tester) async {
    final controller = MarkedTextController(text: 'one | two | three');
    addTearDown(controller.dispose);
    String? changed;

    await tester.pumpWidget(
      wrap(
        controller: controller,
        segmentCount: 3,
        onChanged: (text) => changed = text,
      ),
    );
    await tester.pumpAndSettle();

    final reset = find.widgetWithText(AppButton, 'Сбросить');
    expect(tester.widget<AppButton>(reset).onPressed, isNotNull);

    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(controller.text, 'one two three');
    expect(changed, 'one two three');
  });

  testWidgets('the reset button is locked while there are no markers', (tester) async {
    final controller = MarkedTextController(text: 'one two');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 1));
    await tester.pumpAndSettle();

    final reset = find.widgetWithText(AppButton, 'Сбросить');
    expect(tester.widget<AppButton>(reset).onPressed, isNull);
  });

  testWidgets('marker mode: a click in the text places a separator', (
    tester,
  ) async {
    final controller = MarkedTextController(text: 'alpha beta gamma');
    addTearDown(controller.dispose);
    String? inserted;
    int? insertedOrdinal;

    await tester.pumpWidget(
      wrap(
        controller: controller,
        segmentCount: 1,
        onMarkerInserted: (text, ordinal) {
          inserted = text;
          insertedOrdinal = ordinal;
        },
      ),
    );
    await tester.pumpAndSettle();

    // A tap on the chip enables the mode, then a click in the text places it.
    await tester.tap(find.byType(SegmentMarkerChip));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(TextField)));
    await tester.pumpAndSettle();

    // Insertion is a separate callback; the controller adds the boundary.
    expect(controller.text, contains('|'));
    expect(inserted, contains('|'));
    expect(insertedOrdinal, 1);
  });

  testWidgets('in marker mode the existing markers stay visible', (tester) async {
    final controller = MarkedTextController(text: 'alpha | beta');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SegmentMarkerChip));
    await tester.pumpAndSettle();

    // The toolbar chip needle plus the dimmed needle of the placed marker.
    expect(find.byType(SegmentMarkerNeedle), findsNWidgets(2));
  });

  testWidgets('dragging the chip into the text inserts a separator', (
    tester,
  ) async {
    final controller = MarkedTextController(text: 'alpha beta');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 1));
    await tester.pumpAndSettle();

    final chip = tester.getCenter(find.byType(SegmentMarkerChip));
    final field = tester.getCenter(find.byType(TextField));

    final gesture = await tester.startGesture(chip);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(field);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.text, contains('|'));
  });

  testWidgets('a tap on the needle reports the marker ordinal', (tester) async {
    final controller = MarkedTextController(text: 'alpha | beta | gamma');
    addTearDown(controller.dispose);
    int? removed;

    await tester.pumpWidget(
      wrap(
        controller: controller,
        segmentCount: 3,
        onMarkerRemoved: (ordinal) => removed = ordinal,
      ),
    );
    await tester.pumpAndSettle();

    // The first needle is the source chip; markers follow it.
    await tester.tap(find.byType(SegmentMarkerNeedle).at(1));
    await tester.pumpAndSettle();

    // The controller edits the text from outside; the field does not.
    expect(removed, 1);
    expect(controller.text, 'alpha | beta | gamma');
  });

  testWidgets('the needles are numbered in order', (tester) async {
    final controller = MarkedTextController(text: 'one | two | three');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 3));
    await tester.pumpAndSettle();

    // Two markers: numbers 1 and 2 inside the needle dots.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('dragging a needle moves the marker', (tester) async {
    final controller = MarkedTextController(text: 'alpha | beta gamma');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 2));
    await tester.pumpAndSettle();

    final pin = tester.getCenter(find.byType(SegmentMarkerNeedle).last);
    final fieldRect = tester.getRect(find.byType(TextField));
    final target = Offset(fieldRect.right - 8, fieldRect.center.dy);

    final gesture = await tester.startGesture(pin);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // One marker is left but it moved right of its original place.
    expect(controller.text, contains('|'));
    expect(controller.text, isNot('alpha | beta gamma'));
  });
}
