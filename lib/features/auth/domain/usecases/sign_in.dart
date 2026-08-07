import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Минимальная длина пароля. Совпадает с серверной: пользователь должен
/// получать отказ от формы, а не от сети.
const int kMinPasswordLength = 8;

/// Границы полей профиля (§6). Совпадают с серверными, чтобы форма отвергала
/// неверный ввод сама.
const int kMaxNameLength = 100;
const int kMaxDailyGoalMinutes = 1440;

/// Вход по паре email/пароль.
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password}) {
    validateCredentials(email: email, password: password);
    return _repository.login(email: email, password: password);
  }
}

/// Регистрация нового пользователя. Роль назначает сервер. [name]
/// необязательно — язык и цель задаются позже в настройках.
class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String email,
    required String password,
    String? name,
  }) {
    validateCredentials(email: email, password: password);
    return _repository.register(email: email, password: password, name: name);
  }
}

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

/// Текущий пользователь с сервера: роль могли изменить в админке.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call() => _repository.refreshCurrentUser();
}

/// Правка профиля с клиентской валидацией (имя ≤ [kMaxNameLength], дневная
/// цель `0..`[kMaxDailyGoalMinutes]). Передаём только меняемые поля.
class UpdateProfile {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.length > kMaxNameLength) {
      throw const ValidationFailure(
        'Имя не длиннее $kMaxNameLength символов',
      );
    }
    if (dailyGoalMinutes != null &&
        (dailyGoalMinutes < 0 || dailyGoalMinutes > kMaxDailyGoalMinutes)) {
      throw const ValidationFailure(
        'Дневная цель — от 0 до $kMaxDailyGoalMinutes минут',
      );
    }
    return _repository.updateProfile(
      name: trimmedName,
      studiedLanguage: studiedLanguage,
      dailyGoalMinutes: dailyGoalMinutes,
    );
  }
}

/// Проверки, общие для входа и регистрации.
void validateCredentials({required String email, required String password}) {
  final normalized = email.trim();
  if (normalized.isEmpty) {
    throw const ValidationFailure('Введите email');
  }
  if (!isValidEmail(normalized)) {
    throw const ValidationFailure('Похоже, в email опечатка');
  }
  if (password.length < kMinPasswordLength) {
    throw const ValidationFailure(
      'Пароль должен быть не короче $kMinPasswordLength символов',
    );
  }
}

/// Проверка на явную опечатку, а не на соответствие RFC: настоящую проверку
/// адреса делает только письмо на него.
bool isValidEmail(String email) {
  final pattern = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');
  return pattern.hasMatch(email);
}
