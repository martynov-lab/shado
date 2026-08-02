import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/marked_text_controller.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_marker.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_splitter_field.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Поле-сплиттер: слова живут в обычном поле, разделители ставятся кликом в
/// режиме «Метка» или перетаскиванием. Точную математику проверяет
/// `segment_boundary_math_test`, здесь — проводка виджета.
void main() {
  Widget wrap({
    required MarkedTextController controller,
    required int segmentCount,
    ValueChanged<String>? onChanged,
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
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('показывает чип-метку и число сегментов', (tester) async {
    final controller = MarkedTextController(text: 'one | two | three');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 3));
    await tester.pumpAndSettle();

    expect(find.byType(SegmentMarkerChip), findsOneWidget);
    expect(find.text('Сегментов: 3'), findsOneWidget);
  });

  testWidgets('«Сбросить» снимает все метки', (tester) async {
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

  testWidgets('«Сбросить» заперт, пока меток нет', (tester) async {
    final controller = MarkedTextController(text: 'one two');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 1));
    await tester.pumpAndSettle();

    final reset = find.widgetWithText(AppButton, 'Сбросить');
    expect(tester.widget<AppButton>(reset).onPressed, isNull);
  });

  testWidgets('режим «Метка»: клик по тексту ставит разделитель', (
    tester,
  ) async {
    final controller = MarkedTextController(text: 'alpha beta gamma');
    addTearDown(controller.dispose);
    String? changed;

    await tester.pumpWidget(
      wrap(
        controller: controller,
        segmentCount: 1,
        onChanged: (text) => changed = text,
      ),
    );
    await tester.pumpAndSettle();

    // Включаем режим тапом по чипу, затем ставим метку кликом в тексте.
    await tester.tap(find.byType(SegmentMarkerChip));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(TextField)));
    await tester.pumpAndSettle();

    expect(controller.text, contains('|'));
    expect(changed, contains('|'));
  });

  testWidgets('в режиме «Метка» старые метки остаются видны', (tester) async {
    final controller = MarkedTextController(text: 'alpha | beta');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SegmentMarkerChip));
    await tester.pumpAndSettle();

    // Игла чипа в тулбаре плюс приглушённая игла уже поставленной метки.
    expect(find.byType(SegmentMarkerNeedle), findsNWidgets(2));
  });

  testWidgets('перетаскивание чипа в текст вставляет разделитель', (
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

  testWidgets('тап по игле убирает метку', (tester) async {
    final controller = MarkedTextController(text: 'alpha | beta');
    addTearDown(controller.dispose);
    String? changed;

    await tester.pumpWidget(
      wrap(
        controller: controller,
        segmentCount: 2,
        onChanged: (text) => changed = text,
      ),
    );
    await tester.pumpAndSettle();

    // Иглы рисуются после чипа в тулбаре, поэтому игла метки — последняя.
    await tester.tap(find.byType(SegmentMarkerNeedle).last);
    await tester.pumpAndSettle();

    expect(controller.text, 'alpha beta');
    expect(changed, 'alpha beta');
  });

  testWidgets('перетаскивание иглы переносит метку', (tester) async {
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

    // Метка осталась одна, но переехала правее исходного места.
    expect(controller.text, contains('|'));
    expect(controller.text, isNot('alpha | beta gamma'));
  });
}
