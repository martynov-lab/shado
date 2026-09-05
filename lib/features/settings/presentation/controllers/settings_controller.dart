import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Profile editing from the settings screen; the state is a saving flag.
class SettingsController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Saves the given profile fields; `null` means success.
  Future<String?> save({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    if (state) return null;
    state = true;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: name,
            studiedLanguage: studiedLanguage,
            dailyGoalMinutes: dailyGoalMinutes,
          );
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return 'Не удалось сохранить: $error';
    } finally {
      state = false;
    }
  }
}

/// `true` while the profile is being saved.
final settingsControllerProvider = NotifierProvider<SettingsController, bool>(
  SettingsController.new,
);
