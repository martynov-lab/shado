import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Minimum password length.
const int kMinPasswordLength = 8;

/// Profile field bounds.
const int kMaxNameLength = 100;
const int kMaxDailyGoalMinutes = 1440;

/// Sign-in with an email and password pair.
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password}) {
    validateCredentials(email: email, password: password);
    return _repository.login(email: email, password: password);
  }
}

/// Registers a new user; the server assigns the role.
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

/// Current user from the server.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call() => _repository.refreshCurrentUser();
}

/// Profile update with client-side validation; only changed fields are sent.
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

/// Checks shared by sign-in and sign-up.
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

/// Checks the address for an obvious typo.
bool isValidEmail(String email) {
  final pattern = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');
  return pattern.hasMatch(email);
}
