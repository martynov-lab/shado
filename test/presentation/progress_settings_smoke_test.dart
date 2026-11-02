import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/di/translation_providers.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/item_rating.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/presentation/screens/progress_page.dart';
import 'package:shado/features/settings/presentation/screens/settings_page.dart';
import 'package:shado/features/translation/data/datasources/translation_remote_datasource.dart';
import 'package:shado/features/translation/domain/entities/translation_language.dart';
import 'package:shado/theme/theme.dart';

/// Progress offline: summary and history return instantly, without dio.
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

  @override
  Future<int> putRatings(List<ItemRating> ratings) async => ratings.length;

  @override
  Future<({List<ItemRating> ratings, String serverTime})> getRatings({
    String? since,
  }) async => (ratings: const <ItemRating>[], serverTime: '');
}

/// Translation directory without dio.
class _FakeTranslationRemote implements TranslationRemoteDataSource {
  @override
  Future<List<TranslationLanguage>> languages() async => const [
    TranslationLanguage(code: 'ru', name: 'Русский'),
  ];

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  }) async => texts;
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
          translationRemoteDataSourceProvider.overrideWithValue(
            _FakeTranslationRemote(),
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
    // Let the future providers settle; the summary comes from a fake.
    await tester.pump();
  }

  for (final size in const [
    Size(390, 844),
    Size(640, 960),
    Size(760, 1024),
    Size(1280, 800),
  ]) {
    testWidgets('ProgressPage renders at $size without exceptions', (tester) async {
      await pumpPage(tester, const ProgressPage(), size: size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsPage renders at $size without exceptions', (tester) async {
      await pumpPage(tester, const SettingsPage(), size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
