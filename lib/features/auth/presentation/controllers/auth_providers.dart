import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../lessons/presentation/controllers/lesson_providers.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => ApiAuthRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Сессия. Здесь же сходятся две вещи, которым иначе пришлось бы знать друг о
/// друге: выход из аккаунта чистит кеш уроков, а сетевой слой сообщает, что
/// сессия кончилась.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokens: ref.watch(tokenStorageProvider),
    // Выход чистит и кеш уроков, и локальный прогресс.
    onSignedOut: () async {
      await ref.read(lessonRepositoryProvider).clearCache();
      await ref.read(progressLocalDataSourceProvider).clear();
    },
  );
  // Интерсептор дёргает это, когда сервер отверг refresh: чужие устройства
  // остаются со своими сессиями, а это — выходит.
  ref.read(apiClientProvider).onSessionExpired =
      repository.handleSessionExpired;
  ref.onDispose(repository.dispose);
  return repository;
});

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signUpProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final getCurrentUserProvider = Provider<GetCurrentUser>(
  (ref) => GetCurrentUser(ref.watch(authRepositoryProvider)),
);

final updateProfileProvider = Provider<UpdateProfile>(
  (ref) => UpdateProfile(ref.watch(authRepositoryProvider)),
);
