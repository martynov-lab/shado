import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Правка профиля с экрана настроек. Держит только флаг «идёт сохранение»;
/// сам профиль живёт в [AuthController], туда же уходит обновление.
///
/// Клиентскую валидацию (имя ≤ 100, цель 0..1440) делает use case
/// `UpdateProfile`, серверную — сервер (`422`). Обе приходят сюда как [Failure]
/// с готовым сообщением, поэтому экрану остаётся только показать его.
class SettingsController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Сохраняет переданные поля профиля. Возвращает текст ошибки или `null` при
  /// успехе.
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

/// `true` — идёт сохранение профиля.
final settingsControllerProvider = NotifierProvider<SettingsController, bool>(
  SettingsController.new,
);
