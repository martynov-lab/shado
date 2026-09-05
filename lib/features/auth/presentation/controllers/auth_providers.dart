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

/// Session repository, wired here to cache cleanup and the network layer.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokens: ref.watch(tokenStorageProvider),
    // Signing out clears the lesson cache and local progress.
    onSignedOut: () async {
      await ref.read(lessonRepositoryProvider).clearCache();
      await ref.read(progressLocalDataSourceProvider).clear();
    },
  );
  // The interceptor calls this when the server rejects a refresh.
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
