import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/presentation/controllers/progress_providers.dart';
import 'package:shado/features/progress/presentation/pages/progress_page.dart';
import 'package:shado/features/settings/presentation/pages/settings_page.dart';
import 'package:shado/theme/theme.dart';

/// Прогресс без сети: сводка и история отдаются мгновенно, без dio-таймеров.
class _FakeProgressRemote implements ProgressRemoteDataSource {
  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async => ProgressSummary.fromJson(const {});

  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];
}

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRemoteDataSourceProvider.overrideWithValue(
            _FakeProgressRemote(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: Scaffold(body: page),
        ),
      ),
    );
    await tester.pump();
    // Даём провайдерам-фьючерам разрешиться (сводка приходит из фейка).
    await tester.pump();
  }

  for (final size in const [
    Size(390, 844),
    Size(640, 960),
    Size(760, 1024),
    Size(1280, 800),
  ]) {
    testWidgets('ProgressPage рисуется на $size без исключений', (tester) async {
      await pumpPage(tester, const ProgressPage(), size: size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsPage рисуется на $size без исключений', (tester) async {
      await pumpPage(tester, const SettingsPage(), size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
