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

    // Включаем режим тапом по чипу, затем ставим метку кликом в тексте.
    await tester.tap(find.byType(SegmentMarkerChip));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(TextField)));
    await tester.pumpAndSettle();

    // Вставка метки идёт отдельным колбэком — парную границу поставит контроллер.
    expect(controller.text, contains('|'));
    expect(inserted, contains('|'));
    expect(insertedOrdinal, 1);
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

  testWidgets('тап по игле сообщает номер метки', (tester) async {
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

    // Иглы рисуются после чипа в тулбаре, поэтому первая игла метки — вторая с
    // начала списка (первый — чип), а её номер — 1.
    await tester.tap(find.byType(SegmentMarkerNeedle).at(1));
    await tester.pumpAndSettle();

    // Текст правит контроллер снаружи — само поле его не трогает.
    expect(removed, 1);
    expect(controller.text, 'alpha | beta | gamma');
  });

  testWidgets('иглы пронумерованы по порядку', (tester) async {
    final controller = MarkedTextController(text: 'one | two | three');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller: controller, segmentCount: 3));
    await tester.pumpAndSettle();

    // Две метки — номера 1 и 2 в кружках игл.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
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
