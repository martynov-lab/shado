import '../entities/auth_user.dart';

/// Вход, регистрация и текущая сессия.
///
/// За интерфейсом стоит удалённый источник; контроллеры и роутер тестируются
/// на подделке без сети.
abstract interface class AuthRepository {
  /// Кто вошёл прямо сейчас; `null` — сессии нет.
  AuthUser? get currentUser;

  /// Сессия закончилась не по воле пользователя: refresh отвергнут сервером.
  /// Роутер слушает это, чтобы увести на `/login`.
  Stream<void> get sessionExpired;

  Future<AuthUser> register({
    required String email,
    required String password,
    String? name,
  });

  Future<AuthUser> login({required String email, required String password});

  /// Поднимает сессию по refresh-токену из защищённого хранилища.
  /// `null` — токена нет или сервер его отверг, нужен экран входа.
  Future<AuthUser?> restoreSession();

  /// Перечитывает `/v1/me`: роль могли поменять в админке, и она не ждёт
  /// нового access-токена.
  Future<AuthUser> refreshCurrentUser();

  /// Правит профиль (`PATCH /v1/me`) и обновляет закешированного пользователя.
  /// Передаём только меняемые поля; `null` — поле не трогаем.
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  });

  /// Гасит сессию на сервере и локально. Ошибки сети игнорируются: локально
  /// выход должен состояться в любом случае.
  Future<void> logout();
}
