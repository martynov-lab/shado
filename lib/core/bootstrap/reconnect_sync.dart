import 'dart:async';

import 'package:shado/core/network/network_status.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/lessons/domain/services/lesson_catalog_service.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';
import 'package:shado/features/progress/domain/services/rating_service.dart';

/// Catches the app up with the server when the connection comes back:
/// lessons, the library, the progress and the ratings collected offline.
class ReconnectSync {
  ReconnectSync({
    required NetworkStatus network,
    required AuthService auth,
    required LessonCatalogService catalog,
    required ProgressReporter reporter,
    required ProgressSummaryService progressSummary,
    required RatingService ratings,
  }) : _auth = auth,
       _catalog = catalog,
       _reporter = reporter,
       _progressSummary = progressSummary,
       _ratings = ratings {
    _subscription = network.changes
        .where((online) => online)
        .listen((_) => unawaited(_sync()));
  }

  final AuthService _auth;
  final LessonCatalogService _catalog;
  final ProgressReporter _reporter;
  final ProgressSummaryService _progressSummary;
  final RatingService _ratings;
  late final StreamSubscription<bool> _subscription;

  void dispose() => _subscription.cancel();

  Future<void> _sync() async {
    if (!_auth.session.isAuthenticated) return;
    _catalog.reload();
    await _reporter.flush();
    await _ratings.sync();
    try {
      await _progressSummary.refresh();
    } catch (_) {
      // The saved summary stays until the next try.
    }
  }
}
