import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';

/// A test user; the defaults describe a plain English learner.
AuthUser testUser({
  UserRole role = UserRole.user,
  String email = 'user@example.com',
  String? studiedLanguage = 'en',
}) => AuthUser(
  id: 'user-1',
  email: email,
  role: role,
  createdAt: DateTime.utc(2026),
  studiedLanguage: studiedLanguage,
);

/// Session storage without a server: [user] is signed in from the start.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? user, this.profileError}) : _user = user;

  /// Thrown instead of saving the profile.
  final Object? profileError;

  final List<String?> savedLanguages = [];
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    String? name,
  }) async => _user = testUser(email: email);

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async => _user = testUser(email: email);

  @override
  Future<AuthUser?> restoreSession() async => _user;

  @override
  Future<AuthUser?> restoreOfflineSession() async => _user;

  @override
  Future<AuthUser> refreshCurrentUser() async => _user!;

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    if (profileError != null) throw profileError!;
    savedLanguages.add(studiedLanguage);
    return _user = _user!.copyWith(studiedLanguage: studiedLanguage);
  }

  @override
  Future<void> logout() async => _user = null;
}
