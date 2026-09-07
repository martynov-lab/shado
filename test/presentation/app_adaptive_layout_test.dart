import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/widgets/app_adaptive_layout.dart';

void main() {
  /// Builds [AppAdaptiveLayout] at the given window width.
  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    WidgetBuilder? tablet,
    WidgetBuilder? desktop,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppAdaptiveLayout(
            mobile: (context) => const Text('mobile'),
            tablet: tablet,
            desktop: desktop,
          ),
        ),
      ),
    );
  }

  Text tabletMarker(BuildContext context) => const Text('tablet');
  Text desktopMarker(BuildContext context) => const Text('desktop');

  testWidgets('a narrow window gives the phone layout', (tester) async {
    await pumpAt(tester, 400, tablet: tabletMarker, desktop: desktopMarker);

    expect(find.text('mobile'), findsOneWidget);
    expect(find.text('tablet'), findsNothing);
    expect(find.text('desktop'), findsNothing);
  });

  testWidgets('the middle band gives the tablet layout', (tester) async {
    await pumpAt(tester, 700, tablet: tabletMarker, desktop: desktopMarker);

    expect(find.text('tablet'), findsOneWidget);
  });

  testWidgets('a wide window gives the desktop layout', (tester) async {
    await pumpAt(tester, 1200, tablet: tabletMarker, desktop: desktopMarker);

    expect(find.text('desktop'), findsOneWidget);
  });

  testWidgets('a desktop without its own layout falls back to the tablet one', (tester) async {
    await pumpAt(tester, 1200, tablet: tabletMarker);

    expect(find.text('tablet'), findsOneWidget);
  });

  testWidgets('a tablet without its own layout falls back to the phone one', (tester) async {
    await pumpAt(tester, 700);

    expect(find.text('mobile'), findsOneWidget);
  });
}
