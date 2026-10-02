import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:shado/features/auth/domain/entities/user_session.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';

/// Warms up data for the first frame after sign-in. The router listens to it:
/// it notifies on every session change and when the warm-up ends.
class AppBootstrap extends ChangeNotifier {
  AppBootstrap({
    required AuthService auth,
    required ProgressSummaryService progressSummary,
  }) : _auth = auth,
       _progressSummary = progressSummary {
    _subscription = auth.changes.listen(_onSession);
    _onSession(auth.session);
  }

  static const Duration _timeout = Duration(seconds: 6);

  final AuthService _auth;
  final ProgressSummaryService _progressSummary;
  late final StreamSubscription<UserSession> _subscription;
  bool _isWarm = false;
  bool _isWarming = false;
  bool _isDisposed = false;

  UserSession get session => _auth.session;

  /// The user is signed in but the first-frame data is not ready yet.
  bool get isWarmingUp => session.isAuthenticated && !_isWarm;

  @override
  void dispose() {
    _isDisposed = true;
    _subscription.cancel();
    super.dispose();
  }

  void _onSession(UserSession session) {
    if (!session.isAuthenticated) {
      _isWarm = false;
    } else if (session.isOffline) {
      // Offline there is nothing to fetch — open the cached screens at once.
      _isWarm = true;
    } else if (!_isWarm && !_isWarming) {
      unawaited(_warmUp());
    }
    notifyListeners();
  }

  Future<void> _warmUp() async {
    _isWarming = true;
    try {
      await _progressSummary.load().timeout(_timeout);
    } catch (_) {
      // The summary keeps its error; the splash does not wait for it.
    }
    _isWarming = false;
    if (_isDisposed) return;
    _isWarm = true;
    notifyListeners();
  }
}
